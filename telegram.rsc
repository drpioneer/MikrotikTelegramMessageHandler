# TLGRM - combined notifications script & launch of commands (scripts & functions) via Telegram
# Script uses ideas by Sertik, Virtue, Dimonw, -13-, Mk51, Alice Tails, Chupaka, rextended, sebastia, drPioneer
# https://github.com/drpioneer/MikrotikTelegramMessageHandler
# https://forummikrotik.ru/viewtopic.php?p=89956#p89956
# tested on ROS 6.49.10 & 7.12
# updated 2024/02/28

:global scriptTlgrm; # flag of running script: false=in progress, true=idle
:do {
  :local botID    "botXXXXXXXXXX:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
  :local myChatID "-XXXXXXXXX";
  :local broadCast false; # non-addressed reception mode
  :local launchScr true;  # permission to execute scripts
  :local launchFnc true;  # permission to perform functions
  :local launchCmd true;  # permission to execute commands
  :local sysInfo   true;  # system information broadcast to Telegram
  :local userInfo  false; # user information broadcast to Telegram
  :local emoList {
    "cherry"="%F0%9F%8D%92";"monkey"="%F0%9F%90%92";"crown"="%F0%9F%91%91";"smile"="%F0%9F%98%8E";"bell"="%F0%9F%94%94";"dancer"="%F0%9F%92%83"}
    # emoji list: https://apps.timwhitlock.info/emoji/tables/unicode
  :local emoDev ($emoList->"cherry"); # device emoji in chat
  :global timeAct; # time when the last command was executed
  :global timeLog; # time when the log entries were last sent

  # function of converting CP1251 to UTF8 in URN # https://forum.mikrotik.com/viewtopic.php?p=967513#p967513
  :local CP1251toUTF8inURN do={
    :if ([:typeof $1]!="str" or [:len $1]=0) do={:return ""};
    :local cp1251 {
      "\00";"\01";"\02";"\03";"\04";"\05";"\06";"\07";"\08";"\09";"\0A";"\0B";"\0C";"\0D";"\0E";"\0F";
      "\10";"\11";"\12";"\13";"\14";"\15";"\16";"\17";"\18";"\19";"\1A";"\1B";"\1C";"\1D";"\1E";"\1F";
      "\20";"\22";"\26";"\2B";"\3C";"\3E";"\5B";"\5C";"\5D";"\5E";"\60";"\7B";"\7C";"\7D";"\7E";"\7F";
      "\80";"\81";"\82";"\83";"\84";"\85";"\86";"\87";"\88";"\89";"\8A";"\8B";"\8C";"\8D";"\8E";"\8F";
      "\90";"\91";"\92";"\93";"\94";"\95";"\96";"\97";"\98";"\99";"\9A";"\9B";"\9C";"\9D";"\9E";"\9F";
      "\A0";"\A1";"\A2";"\A3";"\A4";"\A5";"\A6";"\A7";"\A8";"\A9";"\AA";"\AB";"\AC";"\AD";"\AE";"\AF";
      "\B0";"\B1";"\B2";"\B3";"\B4";"\B5";"\B6";"\B7";"\B8";"\B9";"\BA";"\BB";"\BC";"\BD";"\BE";"\BF";
      "\C0";"\C1";"\C2";"\C3";"\C4";"\C5";"\C6";"\C7";"\C8";"\C9";"\CA";"\CB";"\CC";"\CD";"\CE";"\CF";
      "\D0";"\D1";"\D2";"\D3";"\D4";"\D5";"\D6";"\D7";"\D8";"\D9";"\DA";"\DB";"\DC";"\DD";"\DE";"\DF";
      "\E0";"\E1";"\E2";"\E3";"\E4";"\E5";"\E6";"\E7";"\E8";"\E9";"\EA";"\EB";"\EC";"\ED";"\EE";"\EF";
      "\F0";"\F1";"\F2";"\F3";"\F4";"\F5";"\F6";"\F7";"\F8";"\F9";"\FA";"\FB";"\FC";"\FD";"\FE";"\FF"}
    :local utf8 {
      "00";"01";"02";"03";"04";"05";"06";"07";"08";"09";"0A";"0B";"0C";"0D";"0E";"0F";
      "10";"11";"12";"13";"14";"15";"16";"17";"18";"19";"1A";"1B";"1C";"1D";"1E";"1F";
      "20";"22";"26";"2B";"3C";"3E";"5B";"5C";"5D";"5E";"60";"7B";"7C";"7D";"7E";"7F";
      "D082";"D083";"E2809A";"D193";"E2809E";"E280A6";"E280A0";"E280A1";"E282AC";"E280B0";"D089";"E280B9";"D08A";"D08C";"D08B";"D08F";
      "D192";"E28098";"E28099";"E2809C";"E2809D";"E280A2";"E28093";"E28094";"EFBFBD";"E284A2";"D199";"E280BA";"D19A";"D19C";"D19B";"D19F";
      "C2A0";"D08E";"D19E";"D088";"C2A4";"D290";"C2A6";"C2A7";"D081";"C2A9";"D084";"C2AB";"C2AC";"534859";"C2AE";"D087";
      "C2B0";"C2B1";"D086";"D196";"D291";"C2B5";"C2B6";"C2B7";"D191";"E28496";"D194";"C2BB";"D198";"D085";"D195";"D197";
      "D090";"D091";"D092";"D093";"D094";"D095";"D096";"D097";"D098";"D099";"D09A";"D09B";"D09C";"D09D";"D09E";"D09F";
      "D0A0";"D0A1";"D0A2";"D0A3";"D0A4";"D0A5";"D0A6";"D0A7";"D0A8";"D0A9";"D0AA";"D0AB";"D0AC";"D0AD";"D0AE";"D0AF";
      "D0B0";"D0B1";"D0B2";"D0B3";"D0B4";"D0B5";"D0B6";"D0B7";"D0B8";"D0B9";"D0BA";"D0BB";"D0BC";"D0BD";"D0BE";"D0BF";
      "D180";"D181";"D182";"D183";"D184";"D185";"D186";"D187";"D188";"D189";"D18A";"D18B";"D18C";"D18D";"D18E";"D18F"}
    :local res ""; :local urn "";
    :for i from=0 to=([:len $1]-1) do={
      :local sym [:pick $1 $i ($i+1)]; :local idx [:find $cp1251 $sym]; :local utf ($utf8->$idx);
      :if ([:len $utf]=0) do={:set urn $sym}
      :if ([:len $utf]=2) do={:set urn "%$[:pick $utf 0 2]"}
      :if ([:len $utf]=4) do={:set urn "%$[:pick $utf 0 2]%$[:pick $utf 2 4]"}
      :if ([:len $utf]=6) do={:set urn "%$[:pick $utf 0 2]%$[:pick $utf 2 4]%$[:pick $utf 4 6]"}
      :set res "$res$urn"}
    :return $res}

  # function of converting to lowercase letters # https://forum.mikrotik.com/viewtopic.php?p=714396#p714396
  :local LowerCase do={
    :if ([:typeof $1]!="str" or [:len $1]=0) do={:return ""}
    :local lower "abcdefghijklmnopqrstuvwxyz"; :local upper "ABCDEFGHIJKLMNOPQRSTUVWXYZ"; :local res "";
    :for i from=0 to=([:len $1]-1) do={
      :local chr [:pick $1 $i]; :local pos [:find $upper $chr];
      :if ($pos>-1) do={:set chr [:pick $lower $pos]};
      :set res ($res.$chr)}
    :return $res}

  # telegram messenger response parsing function # https://habr.com/ru/post/482802/
  :local MsgParser do={
    :if ([:typeof $1]!="str" or [:len $1]=0) do={:return ""}
    :local variaMod ("\"$2\"");
    :if ([:len [:find $1 $variaMod -1]]=0) do={:return "unknown"}
    :local startLoc ([:find $1 $variaMod -1]+[:len $variaMod]+1);
    :local commaLoc [:find $1 "," $startLoc]; :local brakeLoc [:find $1 "}" $startLoc];
    :local endLoc $commaLoc; :local startSymbol [:pick $1 $startLoc];
    :if ($brakeLoc!=0 && ($commaLoc=0 or $brakeLoc<$commaLoc)) do={:set endLoc $brakeLoc}
    :if ($startSymbol="{") do={:set endLoc ($brakeLoc+1)}
    :if ($3=true) do={:set startLoc ($startLoc+1); :set endLoc ($endLoc-1)}
    :if ($endLoc<$startLoc) do={:set endLoc ($startLoc+1)}
    :return [:pick $1 $startLoc $endLoc]}

  # time translation function to UNIX time # https://forum.mikrotik.com/viewtopic.php?t=75555#p994849
  :local T2U do={ # parses date formats: "hh:mm:ss","mmm/dd hh:mm:ss","mmm/dd/yyyy hh:mm:ss","yyyy-mm-dd hh:mm:ss","mm-dd hh:mm:ss"
    :local dTime [:tostr $1]; :local yesterDay false;
    /system clock;
    :local cYear [get date]; :if ($cYear~"....-..-..") do={:set cYear [:pick $cYear 0 4]} else={:set cYear [:pick $cYear 7 11]}
    :if ([:len $dTime]=10 or [:len $dTime]=11) do={:set dTime "$dTime 00:00:00"}
    :if ([:len $dTime]=15) do={:set dTime "$[:pick $dTime 0 6]/$cYear $[:pick $dTime 7 15]"}
    :if ([:len $dTime]=14) do={:set dTime "$cYear-$[:pick $dTime 0 5] $[:pick $dTime 6 14]"}
    :if ([:len $dTime]=8) do={:if ([:totime $1]>[get time]) do={:set yesterDay true}; :set dTime "$[get date] $dTime"}
    :if ([:tostr $1]="") do={:set dTime ("$[get date] $[get time]")}
    :local vDate [:pick $dTime 0 [:find $dTime " " -1]]; :local vTime [:pick $dTime ([:find $dTime " " -1]+1) [:len $dTime]];
    :local vGmt [get gmt-offset]; :if ($vGmt>0x7FFFFFFF) do={:set vGmt ($vGmt-0x100000000)}; :if ($vGmt<0) do={:set vGmt ($vGmt*-1)}
    :local arrMn [:toarray "0,0,31,59,90,120,151,181,212,243,273,304,334"]; :local vdOff [:toarray "0,4,5,7,8,10"];
    :local month [:tonum [:pick $vDate ($vdOff->2) ($vdOff->3)]];
    :if ($vDate~".../../....") do={
      :set vdOff [:toarray "7,11,1,3,4,6"];
      :set month ([:find "xxanebarprayunulugepctovecANEBARPRAYUNULUGEPCTOVEC" [:pick $vDate ($vdOff->2) ($vdOff->3)] -1]/2);
      :if ($month>12) do={:set month ($month-12)}}
    :local year [:pick $vDate ($vdOff->0) ($vdOff->1)];
    :if ((($year-1968)%4)=0) do={:set ($arrMn->1) -1; :set ($arrMn->2) 30}
    :local toTd ((($year-1970)*365)+(($year-1968)/4)+($arrMn->$month)+([:pick $vDate ($vdOff->4) ($vdOff->5)]-1));
    :if ($yesterDay) do={:set toTd ($toTd-1)}; # bypassing ROS6.xx time format problem after 00:00:00
    :return (((((($toTd*24)+[:pick $vTime 0 2])*60)+[:pick $vTime 3 5])*60)+[:pick $vTime 6 8]-$vGmt)}

  # time conversion function from UNIX time # https://forum.mikrotik.com/viewtopic.php?p=977170#p977170
  :local U2T do={
    :local ZeroFill do={:return [:pick (100+$1) 1 3]}
    :local prMntDays [:toarray "0,0,31,59,90,120,151,181,212,243,273,304,334"];
    :local vGmt [:tonum [/system clock get gmt-offset]];
    :if ($vGmt>0x7FFFFFFF) do={:set vGmt ($vGmt-0x100000000)}
    :if ($vGmt<0) do={:set vGmt ($vGmt*-1)}
    :local tzEpoch ($vGmt+[:tonum $1]);
    :if ($tzEpoch<0) do={:set tzEpoch 0}; # unsupported negative unix epoch
    :local yearStamp (1970+($tzEpoch/31536000));
    :local tmpLeap (($yearStamp-1968)/4);
    :if ((($yearStamp-1968)%4)=0) do={:set ($prMntDays->1) -1; :set ($prMntDays->2) 30}
    :local tmpSec ($tzEpoch%31536000);
    :local tmpDays (($tmpSec/86400)-$tmpLeap);
    :if ($tmpSec<(86400*$tmpLeap) && (($yearStamp-1968)%4)=0) do={
      :set tmpLeap ($tmpLeap-1); :set ($prMntDays->1) 0; :set ($prMntDays->2) 31; :set tmpDays ($tmpDays+1)}
    :if ($tmpSec<(86400*$tmpLeap)) do={:set yearStamp ($yearStamp-1); :set tmpDays ($tmpDays+365)}
    :local mnthStamp 12; :while (($prMntDays->$mnthStamp)>$tmpDays) do={:set mnthStamp ($mnthStamp-1)}
    :local dayStamp [$ZeroFill (($tmpDays+1)-($prMntDays->$mnthStamp))];
    :local timeStamp (00:00:00+[:totime ($tmpSec%86400)]);
    :if ([:len $2]=0) do={:return "$yearStamp/$[$ZeroFill $mnthStamp]/$[$ZeroFill $dayStamp] $timeStamp"} else={:return "$timeStamp"}}

  # system information collection function
  :local SysInfo do={
    :if ([:len $1]=0) do={:return ""};
    :local fndMac ""; :local tmpMac ""; :local tmpAdr ""; :local tmpCmt ""; :local tmpHst ""; :local tmpDyn "";
    :if ($1~"([0-9A-F]{2}[:]){5}[0-9A-F]{2}") do={:set fndMac [:pick $1 ([:find $1 ":"]-2) ([:find $1 ":"]+15)]}
    :if ($fndMac!="") do={ # when any MAC address is detected
      :do {
        /ip dhcp-server lease;
        :set tmpMac [get [find mac-address=$fndMac] mac-address]; 
        :set tmpCmt [get [find mac-address=$fndMac] comment];
        :set tmpHst [get [find mac-address=$fndMac] host-name];
        :set tmpDyn [get [find mac-address=$fndMac status="bound"] dynamic];
        :set tmpAdr [get [find mac-address=$fndMac status="bound"] address]} on-error={}
      :if ($tmpMac="") do={:return "$2 $1 [unfamil MAC]"; # when unfamiliar MAC address
      } else={ # when DHCP-server lease client is actual & with static IP & no comment about DHCP lease
        :if ($tmpDyn!="" && !$tmpDyn && $tmpCmt="") do={:return "$2 $1 $tmpHst $tmpAdr [no comment about DHCP lease]"}}
    } else={:return "$2 $1"}; # when message without MAC address
    :return ""}

  # user information collection function
  :local UsrInfo do={
    :if ([:len $1]=0) do={:return ""};
    :local tmpMac ""; :local tmpAdr ""; :local tmpCmt ""; :local tmpHst ""; :local tmpDyn ""; :local tmpIfc "none"; :local tmpStg "";
    :if ($1~" assigned ((25[0-5]|2[0-4][0-9]|[0-1]?[0-9][0-9]?)[.]){3}(25[0-5]|2[0-4][0-9]|[0-1]?[0-9][0-9]?)") do={
      :if ($1~" to ") do={:set tmpAdr [:pick $1 ([:find $1 " assigned "]+10) ([:find $1 "to"]-1)]}; # specificity of ROS6
      :if ($1~" for ") do={:set tmpAdr [:pick $1 ([:find $1 " assigned "]+10) ([:find $1 "for"]-1)]}}; # specificity of ROS7
    :if ($tmpAdr!="") do={ # when address leasing DHCP server ->
      :do {
        /ip dhcp-server lease;
        :set tmpCmt [get [find address=$tmpAdr] comment]; :set tmpHst [get [find address=$tmpAdr] host-name];
        :set tmpDyn [get [find address=$tmpAdr] dynamic]; :set tmpMac [get [find address=$tmpAdr] mac-address];
        :set tmpIfc [/interface bridge host get [find mac-address=$tmpMac] on-interface];
        :set tmpStg [[:parse "[/interface wireless registration-table get [find last-ip=$tmpAdr] signal-strength-ch0]"]];
        :if ([:len $tmpStg]=0) do={
          :set tmpStg [[:parse "[/interface wifiwave2 registration-table get [find last-ip=$tmpAdr] signal-strength-ch0]"]]}
      } on-error={}
      :if ($tmpStg!="") do={:set tmpStg ($tmpStg."dBm")}
      :local user1 "User1"; :local user2 "User2"; :local whereUser "PLACENAME";
      :if ($tmpDyn!="") do={
        :if ($tmpDyn) do={:return "$[($emoList->"smile")] $2 +$tmpIfc $tmpStg $tmpAdr $tmpHst"; # output when dynamic client
        } else={:return "$tmpCmt $2 +$tmpIfc $tmpStg $tmpAdr $tmpHst"}}; # output when static client
      :if ($tmpCmt=$user1) do={:return "$[($emoList->"bell")] $2 $user1 at $whereUser"}; # output when user1
      :if ($tmpCmt=$user2) do={:return "$[($emoList->"smile")] $2 $user2 at $whereUser"}}; # output when user2
    :return ""}

  # main body
  :local nameID [$LowerCase [/system identity get name]]; # text ID of router
  :local startTime [$U2T [$T2U]]; # start time in nice format
  :put "$startTime\tStart of TLGRM on router:\t$nameID";
  :if ([:len $scriptTlgrm]=0) do={:set scriptTlgrm true}; # creating a script running flag
  :if ($scriptTlgrm) do={ # when script is active ->
    :set scriptTlgrm false; # script running flag is active 
    :if ([:len $timeAct]>0) do={:put "$[$U2T [$T2U]]\tTime executed last command:\t$[$U2T $timeAct]"}
    :if ([:len $timeLog]>0) do={:put "$[$U2T [$T2U]]\tTime sent last log entries:\t$[$U2T $timeLog]"}

    # part of script body to execute via Telegram # https://forummikrotik.ru/viewtopic.php?p=78085
    :put "$[$U2T [$T2U]]\t*** Stage of launch via Telegram ***";
    :local timeStmp [$T2U]; :local httpResp "";
    :local urlStr "https://api.telegram.org/$botID/getUpdates\?offset=-1&limit=1&allowed_updates=message";
    :if ([:len $timeAct]=0) do={:put "$[$U2T [$T2U]]\tTime of last launch not found"; :set timeAct $timeStmp}
    :do {:set httpResp [/tool fetch url=$urlStr as-value output=user]} on-error={}
    :if ([:len $httpResp]!=0) do={ # when Telegram server responded to request ->
      :local content ($httpResp->"data");
      :if ([:len $content]>30) do={
        :local msgTxt [$MsgParser $content "text" true];
        :set msgTxt [:pick $msgTxt ([:find $msgTxt "/" -1]+1) [:len $msgTxt]];
        :if ($msgTxt~"@") do={:set msgTxt [:pick $msgTxt 0 [:find $msgTxt "@"]]}
        :local newStr ""; :local change ""; :local msgAdr "";
        :for i from=0 to=([:len $msgTxt]-1) do={ # cyclic replacement of character '_' by ' '
          :local symb [:pick $msgTxt $i ($i+1)];
          :if ($symb="_") do={:set change " "} else={:set change $symb} 
          :set newStr "$newStr$change"}
        :set msgTxt $newStr;
        :if ($broadCast) do={:set msgAdr $nameID} else={
          :set msgAdr [$LowerCase [:pick $msgTxt 0 [:find $msgTxt " " -1]]];
          :if ([:len [:find $msgTxt " "]]=0) do={:set msgAdr "$msgTxt "}
          :put "$[$U2T [$T2U]]\tRecipient of Telegram message:\t$msgAdr";
          :set msgTxt [:pick $msgTxt ([:find $msgTxt $msgAdr -1]+[:len $msgAdr]+1) [:len $msgTxt]]}
        :if ([:pick $msgTxt 0 1]="\$") do={:set msgTxt [:pick $msgTxt 1 [:len $msgTxt]]}
        :if ([:pick $msgTxt 0 2]="[\$" && [:pick $msgTxt ([:len $msgTxt]-1) [:len $msgTxt]]="]") do={
          :set msgTxt [:pick $msgTxt 2 ([:len $msgTxt]-1)]}; # skipping prefix "$" or [$ .....]
        :if ($msgAdr=$nameID or $msgAdr="forall") do={
          :local chatID [$MsgParser [$MsgParser $content "chat"] "id"];
          :local userNm [$MsgParser $content "username"];
          :set timeStmp [$MsgParser $content "date"];
          :put "$[$U2T [$T2U]]\tSender of Telegram message:\t$userNm \tCommand to execute:\t$msgTxt";
          :local restline [];
          :if ([:len [:find $msgTxt " "]]!=0) do={
            :set restline [:pick $msgTxt ([:find $msgTxt " "]+1) [:len $msgTxt]]; :set msgTxt [:pick $msgTxt 0 [:find $msgTxt " "]]}
          :if ($chatID=$myChatID && $timeAct<$timeStmp) do={
            :set timeAct $timeStmp;
            /system script;
            :if ([environment find name=$msgTxt]!="" && $launchFnc) do={
              :if (([environment get [find name=$msgTxt] value]="(code)")\
                or [:len [:find [environment get [find name=$msgTxt] value] "(eval"]]>0) do={
                :put "$[$U2T [$T2U]]\tRight time to launch function";
                /log warning "Telegram user $userNm launches function: $msgTxt";
                :execute script="[:parse [\$$msgTxt $restline]]";
              } else={
                :put "$[$U2T [$T2U]]\t'$msgTxt' is a global variable and is not launched";
                /log warning "'$msgTxt' is a global variable and is not launched"}}
            :if ([:pick $msgTxt 0 1]="\5C") do={ # allow to perform emoji
              :set msgTxt [:pick $msgTxt 1 [:len $msgTxt]];
              :if ([:find $msgTxt "\5C"]!=0) do={
                :local first [:pick $msgTxt 0 [:find $msgTxt "\5C"]];
                :local after [:pick $msgTxt ([:find $msgTxt "\5C"]+1) [:len $msgTxt]];
                :set msgTxt "$first$after"}}
            :if ([find name=$msgTxt]!="" && $launchScr) do={
              :put "$[$U2T [$T2U]]\tRight time to activate script";
              /log warning "Telegram user $userNm activates script: $msgTxt";
              :execute script="[[:parse \"[:parse [/system script get $msgTxt source]] $restline\"]]"}
            :if ([find name=$msgTxt]="" && [environment find name=$msgTxt]="" && $launchCmd) do={
              :put "$[$U2T [$T2U]]\tRight time to execute command";
              /log warning "Telegram user $userNm is trying to execute command: $msgTxt";
              :do {:execute script="[:parse \"/$msgTxt $restline\"]"} on-error={}}
          } else={:put "$[$U2T [$T2U]]\tWrong time to launch"}
        } else={:put "$[$U2T [$T2U]]\tNo command found for this device"}
      } else={:put "$[$U2T [$T2U]]\tCompletion of response from Telegram"}
    } else={:put "$[$U2T [$T2U]]\tNot response from Telegram"}
    :delay 1s; # time difference between command execution and log broadcast

    # part of script body for notifications in Telegram # https://www.reddit.com/r/mikrotik/comments/onusoj/sending_log_alerts_to_telegram/
    :put "$[$U2T [$T2U]]\t*** Stage of broadcasting to Telegram ***";
    :local logIDs [/log find topics~"warning" or topics~"error" or topics~"critical" or topics~"caps" or\
      topics~"wireless" or topics~"dhcp" or topics~"firewall" or message~" logged "]; # list of potentially interesting log entries
    :local outMsg ""; :local tlgCnt 0; :local logCnt [:len $logIDs]; # counter of suitable log entries
    :if ([:len $timeLog]=0) do={ # when time of last broadcast in Telegram not found ->
      :put "$[$U2T [$T2U]]\tTime of the last log entry was not found";
      :set outMsg "$[$U2T [$T2U] "time"]\tTelegram notification started"; :set tlgCnt ($tlgCnt+1)}
    :if ($timeLog>[$T2U]) do={:set timeLog [$T2U]}; # correction when time of last broadcast to Telegram turned out to be from future
    :if ($logCnt>0) do={ # when log entries are available ->
      :set logCnt ($logCnt-1); # index of last log entry
      :local unxTim ""; :local lstTim [$T2U [/log get [:pick $logIDs $logCnt] time]]; # time of last log entry
      :do {
        :local tmpTim [/log get [:pick $logIDs $logCnt] time]; # message time in router format
        :set unxTim [$T2U $tmpTim]; :set tmpTim [$U2T $unxTim "time"]; # message time
        :if ($unxTim>$timeLog) do={ # selection of actualing log entries ->
          :local tmpMsg [/log get [:pick $logIDs $logCnt] message]; # message body
          :if ($sysInfo) do={
            :local preMsg [$SysInfo $tmpMsg $tmpTim]; # broadcast SYSTEM information
            :if ($preMsg!="") do={
              :set tlgCnt ($tlgCnt+1); :set outMsg "$preMsg\n$outMsg";
              :put "$[$U2T [$T2U]]\tAdded entry: $preMsg"}}
          :if ($userInfo) do={
            :local preMsg [$UsrInfo $tmpMsg $tmpTim]; # broadcast USER information
            :if ($preMsg!="") do={
              :set tlgCnt ($tlgCnt+1); :set outMsg "$preMsg\n$outMsg";
              :put "$[$U2T [$T2U]]\tAdded entry: $preMsg"}}}
        :set logCnt ($logCnt-1);
      } while=($unxTim>$timeLog && $logCnt>-1 && [:len $outMsg]<4096); # iterating through list of messages
      :if ([:len $timeLog]=0 or [:len $timeLog]>0 && $timeLog!=$lstTim && [:len $outMsg]>8) do={
        :set outMsg [$CP1251toUTF8inURN $outMsg]; # converting MESSAGE to UTF8 in URN format
        :if ([:len $emoDev]!=0) do={:set emoDev ("$emoDev%20$nameID:")} else={:set emoDev ("$nameID:")}
        :if ($tlgCnt=1) do={:set outMsg "$emoDev%20$outMsg"} else={:set outMsg "$emoDev%0A$outMsg"}; # solitary message for pop-up notification on phone
        :if ([:len $outMsg]>4096) do={:set outMsg [:pick $outMsg 0 4096]}; # cutting MSG to 4096 bytes
        :set urlStr "https://api.telegram.org/$botID/sendmessage\?chat_id=$myChatID&text=$outMsg";
        :put "$[$U2T [$T2U]]\tGenerated string for Telegram:\t$urlStr";
        :do {:set httpResp [/tool fetch url=$urlStr as-value output=user]; :set timeLog $lstTim} on-error={
          :put "$[$U2T [$T2U]]\tUnsuccessful sending of message to Telegram"}
      } else={:put "$[$U2T [$T2U]]\tThere are no log entries to send"}
    } else={:put "$[$U2T [$T2U]]\tNecessary log entries were not found"}
    :put "$[$U2T [$T2U]]\tEnd of TLGRM-script";
  } else={:put "$startTime\tScript already being executed"; :put "$startTime\tEnd of TLGRM-script"}
} on-error={
  /log warning "Problem in work TLGRM script";
  :put "Script error: It may be worth checking correctness values of variables botID & myChatID"}
:set scriptTlgrm true;
