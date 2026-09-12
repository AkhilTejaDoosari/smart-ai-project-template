#!/usr/bin/env bash
# Structural consistency checker for EVIDENCE.md.
# It does not require every criterion to PASS; final certification owns that gate.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SPEC="$ROOT_DIR/SPEC.md"
EVIDENCE="$ROOT_DIR/EVIDENCE.md"

fail(){ printf 'FAIL: %s\n' "$*" >&2; exit 1; }
[[ -f "$SPEC" ]] || fail "missing SPEC.md"
[[ -f "$EVIDENCE" ]] || fail "missing EVIDENCE.md"

STATUS="$(awk '/^\*\*Status:\*\* (DRAFT|APPROVED)$/{c++;v=$0;sub(/^\*\*Status:\*\* /,"",v)}END{if(c==1)print v}' "$SPEC")"
[[ "$STATUS" == "DRAFT" || "$STATUS" == "APPROVED" ]] || fail "SPEC.md has invalid Status"

set +e
awk -v spec="$SPEC" -v evidence="$EVIDENCE" -v status="$STATUS" '
function issue(m){err++;print "FAIL: " m > "/dev/stderr"}
function trim(s){sub(/^[[:space:]]+/,"",s);sub(/[[:space:]]+$/, "",s);return s}
function normproof(s){gsub(/[[:space:]]/,"",s);return s}
function splitrow(line,  s,n,i){for(i in c)delete c[i];s=line;if(substr(s,1,1)=="|")s=substr(s,2);if(substr(s,length(s),1)=="|")s=substr(s,1,length(s)-1);n=split(s,c,/\|/);for(i=1;i<=n;i++)c[i]=trim(c[i]);return n}
FILENAME==spec{
  if($0~/^## /){in_services=($0=="## 10. External Services and Dependencies");if($0!="## 4. Acceptance Criteria")current_ac=""}
  if($0~/^### AC-[0-9]+ ([-—]) /){x=$0;sub(/^### /,"",x);split(x,a,/ - | — /);current_ac=a[1];acs[current_ac]=1;next}
  if(current_ac!="" && $0~/^\*\*Required proof:\*\*/){x=$0;sub(/^\*\*Required proof:\*\*[[:space:]]*/,"",x);spec_proof[current_ac]=normproof(x);next}
  if($0~/^\|/ && in_services){n=splitrow($0);if(n==10 && c[1]!="Service" && c[1]!~/^-+$/){svc[c[1]]=c[5]}}
  next
}
FILENAME!=evidence{next}
{
  if(index($0,"{{TBD:")>0)evidence_tbd++
}
/^## Acceptance Evidence/{sec="ac";next}
/^## External Integration State/{sec="int";next}
/^## Packaging \/ Deployment Evidence/{sec="pkg";next}
/^## /{sec="";next}
sec=="ac" && /^\|/{
  n=splitrow($0)
  if(n==4 && c[1]!="AC" && c[1]!~/^-+$/){
    id=c[1];gsub(/`/,"",id)
    if(id~/^AC-[0-9]+$/){ev_ac[id]++;ev_proof[id]=normproof(c[2]);result[id]=c[3];ev_text[id]=c[4]}
  }
  next
}
sec=="int" && /^\|/{
  n=splitrow($0)
  if(n==4 && c[1]!="Integration" && c[1]!~/^-+$/){ev_svc[c[1]]++;req[c[1]]=c[2];ach[c[1]]=c[3];svc_evidence[c[1]]=c[4]}
  next
}
sec=="pkg" && /^\|/{
  n=splitrow($0)
  if(n==3 && c[1]!="Gate" && c[1]!~/^-+$/){pkg[c[1]]++;pkg_result[c[1]]=c[2];pkg_evidence[c[1]]=c[3]}
  next
}
END{
  for(id in ev_ac)if(ev_ac[id]>1)issue("duplicate acceptance evidence row for " id)
  for(name in ev_svc)if(ev_svc[name]>1)issue("duplicate integration evidence row for " name)
  for(name in pkg)if(pkg[name]>1)issue("duplicate packaging/deployment evidence row for " name)
  if(status=="APPROVED"){
    if(evidence_tbd>0)issue("approved EVIDENCE.md contains " evidence_tbd " unresolved {{TBD: ... }} marker(s)")
    for(id in acs){
      if(!ev_ac[id])issue("missing acceptance evidence row for " id)
      else {
        if(result[id]!="NOT VERIFIED"&&result[id]!="PASS"&&result[id]!="FAIL")issue(id " evidence Result must be NOT VERIFIED, PASS, or FAIL")
        if(ev_proof[id]!=spec_proof[id])issue(id " Required proof does not match approved SPEC (evidence=" ev_proof[id] ", spec=" spec_proof[id] ")")
        if((result[id]=="PASS"||result[id]=="FAIL")&&trim(ev_text[id])=="")issue(id " " result[id] " evidence requires a non-empty Evidence value")
      }
    }
    for(id in ev_ac)if(!acs[id])issue("EVIDENCE.md references AC not present in approved SPEC: " id)
    for(name in svc){
      if(!ev_svc[name])issue("missing external integration evidence row for " name)
      else {
        if(req[name]!=svc[name])issue("integration " name " Required final state does not match SPEC")
        if(ach[name]!="NOT STARTED"&&ach[name]!="IMPLEMENTED"&&ach[name]!="TESTED"&&ach[name]!="LIVE VERIFIED")issue("integration " name " has invalid Achieved state: " ach[name])
        if(ach[name]!="NOT STARTED"&&trim(svc_evidence[name])=="")issue("integration " name " achieved state " ach[name] " requires non-empty evidence")
      }
    }
    for(name in ev_svc)if(!(name in svc))issue("EVIDENCE.md integration not present in approved SPEC: " name)
    for(name in pkg){
      if(pkg_result[name]!="NOT VERIFIED"&&pkg_result[name]!="PASS"&&pkg_result[name]!="FAIL")issue("packaging/deployment gate " name " Result must be NOT VERIFIED, PASS, or FAIL")
      if((pkg_result[name]=="PASS"||pkg_result[name]=="FAIL")&&trim(pkg_evidence[name])=="")issue("packaging/deployment gate " name " " pkg_result[name] " requires non-empty evidence")
    }
  }
  if(err){print "FAIL: evidence integrity found " err " issue(s)." > "/dev/stderr";exit 1}
  print "CHECK_EVIDENCE_CONTRACT_VERSION=2"
  if(status=="DRAFT")print "PASS: EVIDENCE.md structure available (SPEC DRAFT; semantic coverage deferred).";else print "PASS: EVIDENCE.md matches approved SPEC identifiers and proof contracts."
}' "$SPEC" "$EVIDENCE"
rc=$?
set -e
exit "$rc"
