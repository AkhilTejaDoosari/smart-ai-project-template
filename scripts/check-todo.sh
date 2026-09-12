#!/usr/bin/env bash
# Deterministic TODO.md structural and cross-file integrity checker.
# Portable contract: Bash 3.2+ and POSIX awk.

set -euo pipefail
CHECK_TODO_CONTRACT_VERSION=2
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SPEC_FILE="$ROOT_DIR/SPEC.md"
TODO_FILE="$ROOT_DIR/TODO.md"

fail(){ printf 'FAIL: %s\n' "$*" >&2; exit 1; }
[[ -f "$SPEC_FILE" ]] || fail "missing SPEC.md"
[[ -f "$TODO_FILE" ]] || fail "missing TODO.md"

SPEC_STATUS="$(awk '/^\*\*Status:\*\* (DRAFT|APPROVED)$/{c++;v=$0;sub(/^\*\*Status:\*\* /,"",v)} END{if(c==1)print v}' "$SPEC_FILE")"
[[ "$SPEC_STATUS" == "DRAFT" || "$SPEC_STATUS" == "APPROVED" ]] || fail "SPEC.md must contain exactly one valid Status field"
SPEC_REV="$(awk '/^\*\*Spec revision:\*\* [0-9]+$/{c++;v=$0;sub(/^\*\*Spec revision:\*\* /,"",v)} END{if(c==1)print v}' "$SPEC_FILE")"
[[ "$SPEC_REV" =~ ^[0-9]+$ ]] || fail "SPEC.md must contain exactly one non-negative Spec revision"

set +e
awk -v spec="$SPEC_FILE" -v todo="$TODO_FILE" -v spec_status="$SPEC_STATUS" -v spec_rev="$SPEC_REV" '
function issue(m){err++;print "FAIL: " m > "/dev/stderr"}
function trim(s){sub(/^[[:space:]]+/,"",s);sub(/[[:space:]]+$/, "",s);return s}
function field(line,key){p=key ": ";return index(line,p)==1?substr(line,length(p)+1):""}
function phase_label(p){return "Phase " p}
function scan_tbd(s,   token,pos,rest,closep,nextp,doc){
  scan_complete=0;scan_bad=0;doc="`{{TBD:`";while((pos=index(s,doc))>0)s=substr(s,1,pos-1) substr(s,pos+length(doc));token="{{TBD:"
  while((pos=index(s,token))>0){rest=substr(s,pos+length(token));closep=index(rest,"}}");nextp=index(rest,token);if(closep>0&&(nextp==0||closep<nextp)){scan_complete++;s=substr(rest,closep+2)}else{scan_bad++;if(nextp>0)s=substr(rest,nextp);else break}}
}
FILENAME==spec{
  if($0~/^### AC-[0-9]+ ([-—]) /){x=$0;sub(/^### /,"",x);split(x,a,/ - | — /);ac[a[1]]=1;ac_total++}
  next
}
FILENAME!=todo{next}
{
  scan_tbd($0);tbd+=scan_complete;bad_tbd+=scan_bad
  if($0~/^### Phase/)phase_like++
}
/^\*\*Strategy:\*\*/{strategy_n++;strategy=$0;sub(/^\*\*Strategy:\*\*[[:space:]]*/,"",strategy);next}
/^### Phase [1-9][0-9]* - /{
  x=$0;sub(/^### Phase /,"",x);split(x,a,/ - /);p=a[1]+0;current=p;section="";in_state=0;seen_sub=0
  canonical++;heads[p]++;exists[p]=1;if(heads[p]>1)issue("duplicate phase heading for Phase " p)
  name=$0;sub(/^### Phase [1-9][0-9]* - /,"",name);if(trim(name)=="")issue(phase_label(p) " has empty name");next
}
current==0{next}
/^```text[[:space:]]*$/{if(!seen_sub){state_open[current]++;in_state=1;next}}
/^```[[:space:]]*$/{if(in_state){state_close[current]++;in_state=0;next}}
/^#### /{seen_sub=1;in_state=0;section=$0;sub(/^#### /,"",section);sections[current SUBSEP section]++;next}
/^---[[:space:]]*$/{in_state=0;section="";next}
{
  keys[1]="Status";keys[2]="Mode";keys[3]="Depends on";keys[4]="Defined against";keys[5]="Completed against";keys[6]="AUTO executor";keys[7]="AUTO iteration budget"
  for(i=1;i<=7;i++){k=keys[i];if(index($0,k ": ")==1){fc[current SUBSEP k]++;fv[current SUBSEP k]=field($0,k);if(!in_state)fo[current SUBSEP k]++;next}}
  if(in_state && trim($0)!="")state_extra[current]++
  if(section=="Agenda" && trim($0)!="")agenda[current]++
  if(section=="Acceptance Coverage"){
    if($0~/^- `AC-[0-9]+`[[:space:]]*$/){id=$0;sub(/^- `/,"",id);sub(/`[[:space:]]*$/,"",id);refs[current SUBSEP id]=1;owned[id]=1}
    else if(index($0,"AC-")>0&&trim($0)!="")bad_ac[current]++
  }
  if(section=="To-do list"){
    if($0~/^- \[[ xX]\][[:space:]]+/)tasks[current]++
    else if($0~/^- \[[ xX]\]([^[:space:]]|$)/)bad_task[current]++
  }
  if(section=="Blocker"&&trim($0)!=""){block_lines[current]++;if(trim($0)=="None")block_none[current]++;else block_detail[current]++}
}
END{
  if(phase_like>0 && canonical==0)issue("TODO.md contains phase-like headings but zero canonical `### Phase N - Name` headings were parsed")
  if(phase_like!=canonical)issue("TODO.md contains " phase_like-canonical " noncanonical phase-like heading(s); use exactly `### Phase N - Name`")
  if(bad_tbd>0)issue("TODO.md contains " bad_tbd " unterminated placeholder marker(s)")
  if(spec_status=="APPROVED" && canonical==0)issue("approved project TODO.md contains no phases")
  if(strategy_n!=1)issue("TODO.md must contain exactly one Execution Strategy field")
  else if(spec_status=="APPROVED" && strategy!="CONSERVATIVE"&&strategy!="HYBRID"&&strategy!="AUTONOMOUS"&&strategy!="CUSTOM")issue("Execution Strategy must be CONSERVATIVE, HYBRID, AUTONOMOUS, or CUSTOM")
  for(p in exists){
    if(state_open[p]!=1||state_close[p]!=1)issue(phase_label(p) " must contain exactly one closed ```text state block")
    if(state_extra[p])issue(phase_label(p) " state block contains unexpected content")
    split("Status|Mode|Depends on|Defined against|Completed against|AUTO executor|AUTO iteration budget",ka,/\|/)
    for(i=1;i<=7;i++){k=ka[i];if(fc[p SUBSEP k]!=1)issue(phase_label(p) " must contain exactly one " k " field");if(fo[p SUBSEP k])issue(phase_label(p) " has " k " outside the state block")}
    st[p]=fv[p SUBSEP "Status"];mo[p]=fv[p SUBSEP "Mode"];dp[p]=fv[p SUBSEP "Depends on"];de[p]=fv[p SUBSEP "Defined against"];co[p]=fv[p SUBSEP "Completed against"];ex[p]=fv[p SUBSEP "AUTO executor"];bu[p]=fv[p SUBSEP "AUTO iteration budget"]
    if(st[p]!="Not Started"&&st[p]!="In Progress"&&st[p]!="Blocked"&&st[p]!="Done")issue(phase_label(p) " has invalid Status: " st[p])
    if(spec_status=="APPROVED"){
      if(mo[p]!="MANUAL"&&mo[p]!="AUTO")issue(phase_label(p) " has invalid Mode: " mo[p])
      if(mo[p]=="MANUAL"&&(ex[p]!="—"||bu[p]!="—"))issue(phase_label(p) " MANUAL phase must use AUTO executor: — and AUTO iteration budget: —")
      if(mo[p]=="AUTO"&&ex[p]=="—")issue(phase_label(p) " AUTO phase must select AUTO executor: NONE or an executor name")
      if(mo[p]=="AUTO"&&ex[p]=="NONE"&&bu[p]!="—")issue(phase_label(p) " policy-only AUTO with executor NONE must use budget: —")
      if(mo[p]=="AUTO"&&ex[p]!=""&&ex[p]!="NONE"&&ex[p]!="—"&&ex[p]!~/^[A-Za-z0-9._-]+$/)issue(phase_label(p) " AUTO executor name must use letters, numbers, dot, underscore, or hyphen")
      if(mo[p]=="AUTO"&&ex[p]!=""&&ex[p]!="NONE"&&ex[p]!="—"&&bu[p]!~/^[1-9][0-9]*$/)issue(phase_label(p) " AUTO executor requires a positive integer iteration budget")
    }
    if(st[p]=="Not Started"&&(de[p]!="—"||co[p]!="—"))issue(phase_label(p) " Not Started phase must have both revision fields as —")
    if(st[p]=="In Progress"||st[p]=="Blocked"){if(de[p]!~/^Spec revision [0-9]+$/)issue(phase_label(p) " requires Defined against: Spec revision N");if(co[p]!="—")issue(phase_label(p) " active phase must have Completed against: —")}
    if(st[p]=="Done"){
      if(de[p]!~/^Spec revision [0-9]+$/||co[p]!~/^Spec revision [0-9]+$/)issue(phase_label(p) " Done revision fields are malformed")
      d1=de[p];d2=co[p];sub(/^Spec revision /,"",d1);sub(/^Spec revision /,"",d2)
      if(d1~/^[0-9]+$/&&d2~/^[0-9]+$/&&d2+0<d1+0)issue(phase_label(p) " completion revision predates defined revision")
      if(d2~/^[0-9]+$/&&d2+0>spec_rev+0)issue(phase_label(p) " completion revision is newer than current SPEC revision")
    }
    if((st[p]=="In Progress"||st[p]=="Blocked")&&de[p]~/^Spec revision [0-9]+$/){d1=de[p];sub(/^Spec revision /,"",d1);if(d1+0>spec_rev+0)issue(phase_label(p) " Defined against is newer than current SPEC revision")}
    split("Agenda|Acceptance Coverage|To-do list|Blocker",sa,/\|/);for(i=1;i<=4;i++)if(sections[p SUBSEP sa[i]]!=1)issue(phase_label(p) " must contain exactly one #### " sa[i])
    if(!agenda[p])issue(phase_label(p) " Agenda is empty");if(!tasks[p]&&!bad_task[p])issue(phase_label(p) " To-do list contains no task checkboxes");if(bad_task[p])issue(phase_label(p) " contains malformed task checkbox syntax")
    if(!block_lines[p])issue(phase_label(p) " Blocker is empty");if(st[p]=="Blocked"){if(!block_detail[p]||block_none[p])issue(phase_label(p) " is Blocked but has no real blocker") } else if(block_lines[p]!=1||block_none[p]!=1)issue(phase_label(p) " is not Blocked and Blocker must be exactly None")
    if(spec_status=="APPROVED"){
      if(dp[p]!="None"){n=split(dp[p],da,/,[[:space:]]*/);for(i=1;i<=n;i++){x=trim(da[i]);if(x!~/^Phase [1-9][0-9]*$/){issue(phase_label(p) " has malformed dependency: " x);continue}sub(/^Phase /,"",x);d=x+0;edge[p SUBSEP d]=1;if(d==p)issue(phase_label(p) " depends on itself")}}
    }
  }
  if(spec_status=="APPROVED"){
    if(tbd>0)issue("approved TODO.md contains " tbd " complete {{TBD: ... }} placeholder(s)")
    for(e in edge){split(e,a,SUBSEP);p=a[1];d=a[2];if(!exists[d])issue(phase_label(p) " depends on missing Phase " d);else if((st[p]=="In Progress"||st[p]=="Blocked"||st[p]=="Done")&&st[d]!="Done")issue(phase_label(p) " started before dependency Phase " d " was Done")}
    # Kahn-style cycle detection over existing phase dependency edges.
    for(p in exists){indegree[p]=0;removed[p]=0}
    for(e in edge){split(e,a,SUBSEP);if(exists[a[1]]&&exists[a[2]])indegree[a[1]]++}
    processed=0;changed=1
    while(changed){changed=0;for(p in exists){if(!removed[p]&&indegree[p]==0){removed[p]=1;processed++;changed=1;for(e in edge){split(e,a,SUBSEP);if(a[2]==p&&exists[a[1]]&&!removed[a[1]])indegree[a[1]]--}}}}
    if(processed!=canonical)issue("phase dependency graph contains a cycle")
    for(r in refs){split(r,a,SUBSEP);if(!ac[a[2]])issue(phase_label(a[1]) " references missing acceptance criterion " a[2])}
    for(id in ac)if(!owned[id])issue("approved acceptance criterion " id " is not owned by any TODO phase")
  }
  if(err){print "FAIL: TODO integrity check found " err " issue(s)." > "/dev/stderr";exit 1}
  print "CHECK_TODO_CONTRACT_VERSION=2"
  if(spec_status=="DRAFT")print "PASS: TODO structure passed (SPEC DRAFT; semantic planning checks deferred, " canonical " phase(s))."
  else print "PASS: TODO integrity passed (" canonical " phase(s), " ac_total " acceptance criterion/criteria in SPEC)."
}' "$SPEC_FILE" "$TODO_FILE"
rc=$?
set -e
exit "$rc"
