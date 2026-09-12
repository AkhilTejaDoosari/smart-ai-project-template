#!/usr/bin/env bash
# Deterministic SPEC.md approval-readiness / approved-integrity checker.
# Portable contract: Bash 3.2+ and POSIX awk; no GNU-only sed/grep behavior.

set -euo pipefail
CHECK_SPEC_CONTRACT_VERSION=2
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SPEC_FILE="$ROOT_DIR/SPEC.md"

[[ -f "$SPEC_FILE" ]] || { echo "FAIL: missing SPEC.md" >&2; exit 1; }

set +e
awk '
function trim(s){sub(/^[[:space:]]+/,"",s);sub(/[[:space:]]+$/, "",s);return s}
function issue(msg,w){if(w=="")w=1; msgs[++msgc]=msg; errors+=w}
function money_cents(s,a){split(s,a,/\./); return (a[1]+0)*100+(a[2]+0)}
function heading_key(line){
  if(line=="## Template Conventions")return "Template Conventions"
  if(line=="## Approval")return "Approval"
  if(line ~ /^## [1-9][0-9]*\. /){x=line; sub(/^## /,"",x); sub(/\..*/,"",x); return x}
  return ""
}
function split_md_row(line,   s,i,c,esc,cell,n,k){
  for(k in cellv)delete cellv[k]; s=line
  if(substr(s,1,1)=="|")s=substr(s,2); if(substr(s,length(s),1)=="|")s=substr(s,1,length(s)-1)
  esc=0;cell="";n=0
  for(i=1;i<=length(s);i++){
    c=substr(s,i,1)
    if(esc){cell=cell c;esc=0;continue}
    if(c=="\\"){esc=1;continue}
    if(c=="|"){cellv[++n]=trim(cell);cell=""}else cell=cell c
  }
  cellv[++n]=trim(cell); return n
}
function scan_tbd(s,   token,pos,rest,closep,nextp,doc){
  scan_complete=0;scan_bad=0;doc="`{{TBD:`"
  while((pos=index(s,doc))>0)s=substr(s,1,pos-1) substr(s,pos+length(doc))
  token="{{TBD:"
  while((pos=index(s,token))>0){
    rest=substr(s,pos+length(token)); closep=index(rest,"}}"); nextp=index(rest,token)
    if(closep>0 && (nextp==0 || closep<nextp)){scan_complete++;s=substr(rest,closep+2)}
    else {scan_bad++; if(nextp>0)s=substr(rest,nextp);else break}
  }
}
function req_id(line, x,a){x=line;sub(/^- `/,"",x);split(x,a,/`/);return a[1]}
function ac_id(line,x,a){x=line;sub(/^### /,"",x);split(x,a,/ - | — /);return a[1]}
function parse_satisfies(line,ac,  s,n,a,i,t){
  s=line;sub(/^\*\*Satisfies:\*\*[[:space:]]*/,"",s);gsub(/`|,/," ",s);n=split(s,a,/[[:space:]]+/)
  for(i=1;i<=n;i++){t=trim(a[i]);if(t~/^(REQ|NFR)-[0-9]+$/){ac_req[ac SUBSEP t]=1; covered[t]=1; sats_valid[ac]++}}
}
BEGIN{
  required["Template Conventions"]=1;for(i=1;i<=15;i++)required[i]=1;required["Approval"]=1
}
{
  scan_tbd($0); tbd+=scan_complete; bad_tbd+=scan_bad
}
/^## /{
  k=heading_key($0); if(k!=""){heads[k]++; section=(k~/^[0-9]+$/)?k+0:(k=="Approval"?100:-1)}else section=-2
  current_ac=""; next
}
/^### /{
  if(section>=9 && section<=13)subheads[section]++
  if(section==4 && $0~/^### AC-[0-9]+ ([-—]) /){current_ac=ac_id($0); ac_count[current_ac]++; acs[current_ac]=1; next}
  if(section==4)current_ac=""
  next
}
section==1 && /^\*\*Status:\*\*/{status_n++; x=$0;sub(/^\*\*Status:\*\*[[:space:]]*/,"",x);status=x;next}
section==1 && /^\*\*Spec revision:\*\*/{rev_n++;x=$0;sub(/^\*\*Spec revision:\*\*[[:space:]]*/,"",x);rev=x;next}
section==1 && /^\*\*Entry:\*\*/{entry_n++;x=$0;sub(/^\*\*Entry:\*\*[[:space:]]*/,"",x);entry=x;next}
section==1 && /^\*\*Rigor:\*\*/{rigor_n++;x=$0;sub(/^\*\*Rigor:\*\*[[:space:]]*/,"",x);rigor=x;next}
section==1 && /^\*\*Monthly budget USD:\*\*/{budget_n++;x=$0;sub(/^\*\*Monthly budget USD:\*\*[[:space:]]*/,"",x);budget=x;next}
section>=9 && section<=13 && /^\*\*Applicability:\*\*/{app_n[section]++;x=$0;sub(/^\*\*Applicability:\*\*[[:space:]]*/,"",x);app[section]=x;next}
section==3 && /^- `REQ-[0-9]+` - |^- `REQ-[0-9]+` — /{id=req_id($0);reqs[id]=1;req_count[id]++;next}
section==3 && /^- `NFR-[0-9]+` - |^- `NFR-[0-9]+` — /{id=req_id($0);reqs[id]=1;req_count[id]++;next}
section==4 && current_ac!="" && /^\*\*Satisfies:\*\*/{sats_n[current_ac]++;parse_satisfies($0,current_ac);next}
section==4 && current_ac!="" && /^\*\*Required proof:\*\*/{
  proof_n[current_ac]++;x=$0;sub(/^\*\*Required proof:\*\*[[:space:]]*/,"",x);proof[current_ac]=x;next
}
section==15 && /^\*\*State:\*\*/{oq_state_n++;x=$0;sub(/^\*\*State:\*\*[[:space:]]*/,"",x);oq_state=x;next}
section==15 && /^- \[ \]/{if(index($0,"{{TBD:")==0)open_q++;next}
section==10 && /^\|/{
  n=split_md_row($0)
  if(n==10 && cellv[1]=="Service" && cellv[2]=="Need" && cellv[3]=="Production Provider" && cellv[4]=="Automated Test Provider" && cellv[5]=="Required Final State" && cellv[6]=="Free Tier / Limit" && cellv[7]=="Estimated Monthly Cost USD" && cellv[8]=="Variable-Cost Risk" && cellv[9]=="Pricing Notes" && cellv[10]=="Alternative"){svc_header++;next}
  sep=1;for(i=1;i<=n;i++)if(cellv[i]!~/^:?-+:?$/)sep=0;if(sep){svc_sep++;next}
  svc_rows++;svc_cols[svc_rows]=n;for(i=1;i<=n;i++)svc[svc_rows SUBSEP i]=cellv[i];svc_name_count[trim(cellv[1])]++;next
}
END{
  if(tbd>0)issue(tbd " complete {{TBD: ... }} placeholder(s) remain",tbd)
  if(bad_tbd>0)issue(bad_tbd " unterminated placeholder marker(s) remain",bad_tbd)
  for(k in required){if(heads[k]!=1)issue("required top-level heading must appear exactly once: " k)}
  if(status_n!=1 || (status!="DRAFT" && status!="APPROVED"))issue("§1 Status must appear exactly once and be DRAFT or APPROVED")
  if(rev_n!=1 || rev!~/^[0-9]+$/)issue("§1 Spec revision must be a non-negative integer")
  if(entry_n!=1)issue("§1 Entry must appear exactly once"); else if(index(entry,"{{TBD:")==0 && entry!="NEW" && entry!="ADOPT")issue("§1 Entry must be NEW or ADOPT")
  if(rigor_n!=1)issue("§1 Rigor must appear exactly once"); else if(index(rigor,"{{TBD:")==0 && rigor!="LEAN" && rigor!="STANDARD" && rigor!="STRICT")issue("§1 Rigor must be LEAN, STANDARD, or STRICT")
  if(budget_n!=1 || budget!~/^[0-9]+\.[0-9][0-9]$/)issue("§1 Monthly budget USD must use two decimal places")
  if(status=="APPROVED" && rev~/^[0-9]+$/ && rev+0<1)issue("APPROVED SPEC cannot have Spec revision 0")
  for(i=9;i<=13;i++){
    if(app_n[i]!=1)issue("§" i " must contain exactly one Applicability field"); else if(index(app[i],"{{TBD:")==0 && app[i]!="YES" && app[i]!="N/A")issue("§" i " Applicability must be YES or N/A")
    if(app[i]=="N/A" && subheads[i]>0)issue("§" i " is N/A but still contains ### subsection content")
  }
  for(id in req_count)if(req_count[id]>1)issue("duplicate requirement ID: " id)
  for(ac in acs){
    if(ac_count[ac]>1)issue("duplicate acceptance criterion ID: " ac)
    if(sats_n[ac]!=1 || sats_valid[ac]<1)issue(ac " must contain exactly one Satisfies line with at least one REQ/NFR ID")
    if(proof_n[ac]!=1)issue(ac " must contain exactly one Required proof field")
    else if(index(proof[ac],"{{TBD:")==0){
      p=proof[ac];gsub(/[[:space:]]/,"",p); n=split(p,a,/,/); if(n<1)issue(ac " Required proof is empty")
      for(i=1;i<=n;i++)if(a[i]!="NORMAL"&&a[i]!="SMOKE"&&a[i]!="LIVE"&&a[i]!="MANUAL")issue(ac " has invalid Required proof class: " a[i])
    }
  }
  for(pair in ac_req){split(pair,a,SUBSEP);if(!reqs[a[2]])issue(a[1] " references missing requirement " a[2])}
  for(id in reqs)if(!covered[id])issue(id " lacks AC coverage")
  if(oq_state_n!=1)issue("§15 State must appear exactly once"); else if(index(oq_state,"{{TBD:")==0 && oq_state!="OPEN"&&oq_state!="CLEAR")issue("§15 State must be OPEN or CLEAR")
  if(oq_state=="CLEAR" && open_q>0)issue("§15 is CLEAR but unchecked questions remain")
  if(status=="APPROVED" && oq_state!="CLEAR")issue("APPROVED SPEC requires §15 State: CLEAR")
  if(app[10]=="YES"){
    if(svc_header!=1)issue("§10 service table must contain the canonical 10-column header")
    if(svc_sep<1)issue("§10 service table separator is missing")
    if(svc_rows<1)issue("§10 is applicable but contains no service row")
    for(name in svc_name_count)if(name!=""&&svc_name_count[name]>1)issue("§10 contains duplicate Service name: " name)
    for(r=1;r<=svc_rows;r++){
      if(svc_cols[r]!=10){issue("§10 service row " r " must contain exactly 10 columns");continue}
      for(c=1;c<=6;c++)if(trim(svc[r SUBSEP c])=="")issue("§10 service row " r " has an empty required field in column " c)
      if(trim(svc[r SUBSEP 10])=="")issue("§10 service row " r " is missing Alternative")
      state=trim(svc[r SUBSEP 5]); if(state!="IMPLEMENTED"&&state!="TESTED"&&state!="LIVE VERIFIED")issue("§10 service row " r " has invalid Required Final State")
      cost=trim(svc[r SUBSEP 7]);if(cost!~/^[0-9]+\.[0-9][0-9]$/)issue("§10 service row " r " cost must use two decimal places");else total+=money_cents(cost)
      risk=trim(svc[r SUBSEP 8]);notes=trim(svc[r SUBSEP 9]);if(risk!="LOW"&&risk!="MEDIUM"&&risk!="HIGH")issue("§10 service row " r " Variable-Cost Risk must be LOW, MEDIUM, or HIGH");else if((risk=="MEDIUM"||risk=="HIGH")&&notes=="")issue("§10 service row " r " requires Pricing Notes for " risk " risk")
    }
    if(budget~/^[0-9]+\.[0-9][0-9]$/ && total>money_cents(budget))issue("summed external-service cost exceeds Monthly budget USD")
  }
  if(errors){
    if(status=="DRAFT")print "NOT READY FOR APPROVAL — " errors " item(s) outstanding." > "/dev/stderr"; else print "FAIL: SPEC integrity check found " errors " issue(s)." > "/dev/stderr"
    for(i=1;i<=msgc;i++)print "  - " msgs[i] > "/dev/stderr"; exit 1
  }
  print "CHECK_SPEC_CONTRACT_VERSION=2"
  if(status=="DRAFT")print "READY FOR HUMAN APPROVAL — mechanical checks passed."; else print "PASS: approved SPEC integrity passed."
}' "$SPEC_FILE"
rc=$?
set -e
exit "$rc"
