#!/bin/sh
# This script was generated using Makeself 2.3.1

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2489202989"
MD5="728c3e3441fc91525d10379918018d2e"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="N2RJ VPN script for Softether"
script="./vpninstall.sh"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="vpnsetup"
filesizes="2264"
keep="n"
nooverwrite="n"
quiet="n"
nodiskspace="n"
export_conf="n"

print_cmd_arg=""
if type printf > /dev/null; then
    print_cmd="printf"
elif test -x /usr/ucb/echo; then
    print_cmd="/usr/ucb/echo"
else
    print_cmd="echo"
fi
	
if test -d /usr/xpg4/bin; then
    PATH=/usr/xpg4/bin:$PATH
    export PATH
fi

unset CDPATH

MS_Printf()
{
    $print_cmd $print_cmd_arg "$1"
}

MS_PrintLicense()
{
  if test x"$licensetxt" != x; then
    echo "$licensetxt"
    while true
    do
      MS_Printf "Please type y to accept, n otherwise: "
      read yn
      if test x"$yn" = xn; then
        keep=n
	eval $finish; exit 1
        break;
      elif test x"$yn" = xy; then
        break;
      fi
    done
  fi
}

MS_diskspace()
{
	(
	df -kP "$1" | tail -1 | awk '{ if ($4 ~ /%/) {print $3} else {print $4} }'
	)
}

MS_dd()
{
    blocks=`expr $3 / 1024`
    bytes=`expr $3 % 1024`
    dd if="$1" ibs=$2 skip=1 obs=1024 conv=sync 2> /dev/null | \
    { test $blocks -gt 0 && dd ibs=1024 obs=1024 count=$blocks ; \
      test $bytes  -gt 0 && dd ibs=1 obs=1024 count=$bytes ; } 2> /dev/null
}

MS_dd_Progress()
{
    if test x"$noprogress" = xy; then
        MS_dd $@
        return $?
    fi
    file="$1"
    offset=$2
    length=$3
    pos=0
    bsize=4194304
    while test $bsize -gt $length; do
        bsize=`expr $bsize / 4`
    done
    blocks=`expr $length / $bsize`
    bytes=`expr $length % $bsize`
    (
        dd ibs=$offset skip=1 2>/dev/null
        pos=`expr $pos \+ $bsize`
        MS_Printf "     0%% " 1>&2
        if test $blocks -gt 0; then
            while test $pos -le $length; do
                dd bs=$bsize count=1 2>/dev/null
                pcent=`expr $length / 100`
                pcent=`expr $pos / $pcent`
                if test $pcent -lt 100; then
                    MS_Printf "\b\b\b\b\b\b\b" 1>&2
                    if test $pcent -lt 10; then
                        MS_Printf "    $pcent%% " 1>&2
                    else
                        MS_Printf "   $pcent%% " 1>&2
                    fi
                fi
                pos=`expr $pos \+ $bsize`
            done
        fi
        if test $bytes -gt 0; then
            dd bs=$bytes count=1 2>/dev/null
        fi
        MS_Printf "\b\b\b\b\b\b\b" 1>&2
        MS_Printf " 100%%  " 1>&2
    ) < "$file"
}

MS_Help()
{
    cat << EOH >&2
${helpheader}Makeself version 2.3.1
 1) Getting help or info about $0 :
  $0 --help   Print this message
  $0 --info   Print embedded info : title, default target directory, embedded script ...
  $0 --lsm    Print embedded lsm entry (or no LSM)
  $0 --list   Print the list of files in the archive
  $0 --check  Checks integrity of the archive

 2) Running $0 :
  $0 [options] [--] [additional arguments to embedded script]
  with following options (in that order)
  --confirm             Ask before running embedded script
  --quiet		Do not print anything except error messages
  --noexec              Do not run embedded script
  --keep                Do not erase target directory after running
			the embedded script
  --noprogress          Do not show the progress during the decompression
  --nox11               Do not spawn an xterm
  --nochown             Do not give the extracted files to the current user
  --nodiskspace         Do not check for available disk space
  --target dir          Extract directly to a target directory
                        directory path can be either absolute or relative
  --tar arg1 [arg2 ...] Access the contents of the archive through the tar command
  --                    Following arguments will be passed to the embedded script
EOH
}

MS_Check()
{
    OLD_PATH="$PATH"
    PATH=${GUESS_MD5_PATH:-"$OLD_PATH:/bin:/usr/bin:/sbin:/usr/local/ssl/bin:/usr/local/bin:/opt/openssl/bin"}
	MD5_ARG=""
    MD5_PATH=`exec <&- 2>&-; which md5sum || command -v md5sum || type md5sum`
    test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which md5 || command -v md5 || type md5`
	test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which digest || command -v digest || type digest`
    PATH="$OLD_PATH"

    if test x"$quiet" = xn; then
		MS_Printf "Verifying archive integrity..."
    fi
    offset=`head -n 546 "$1" | wc -c | tr -d " "`
    verb=$2
    i=1
    for s in $filesizes
    do
		crc=`echo $CRCsum | cut -d" " -f$i`
		if test -x "$MD5_PATH"; then
			if test x"`basename $MD5_PATH`" = xdigest; then
				MD5_ARG="-a md5"
			fi
			md5=`echo $MD5 | cut -d" " -f$i`
			if test x"$md5" = x00000000000000000000000000000000; then
				test x"$verb" = xy && echo " $1 does not contain an embedded MD5 checksum." >&2
			else
				md5sum=`MS_dd_Progress "$1" $offset $s | eval "$MD5_PATH $MD5_ARG" | cut -b-32`;
				if test x"$md5sum" != x"$md5"; then
					echo "Error in MD5 checksums: $md5sum is different from $md5" >&2
					exit 2
				else
					test x"$verb" = xy && MS_Printf " MD5 checksums are OK." >&2
				fi
				crc="0000000000"; verb=n
			fi
		fi
		if test x"$crc" = x0000000000; then
			test x"$verb" = xy && echo " $1 does not contain a CRC checksum." >&2
		else
			sum1=`MS_dd_Progress "$1" $offset $s | CMD_ENV=xpg4 cksum | awk '{print $1}'`
			if test x"$sum1" = x"$crc"; then
				test x"$verb" = xy && MS_Printf " CRC checksums are OK." >&2
			else
				echo "Error in checksums: $sum1 is different from $crc" >&2
				exit 2;
			fi
		fi
		i=`expr $i + 1`
		offset=`expr $offset + $s`
    done
    if test x"$quiet" = xn; then
		echo " All good."
    fi
}

UnTAR()
{
    if test x"$quiet" = xn; then
		tar $1vf - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
    else

		tar $1f - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
    fi
}

finish=true
xterm_loop=
noprogress=n
nox11=n
copy=none
ownership=y
verbose=n

initargs="$@"

while true
do
    case "$1" in
    -h | --help)
	MS_Help
	exit 0
	;;
    -q | --quiet)
	quiet=y
	noprogress=y
	shift
	;;
    --info)
	echo Identification: "$label"
	echo Target directory: "$targetdir"
	echo Uncompressed size: 12 KB
	echo Compression: gzip
	echo Date of packaging: Thu May 25 15:08:49 EDT 2017
	echo Built with Makeself version 2.3.1 on darwin16
	echo Build command was: "./makeself.sh \\
    \"../vpnsetup/\" \\
    \"n2rj_vpnsetup.sh\" \\
    \"N2RJ VPN script for Softether\" \\
    \"./vpninstall.sh\""
	if test x"$script" != x; then
	    echo Script run after extraction:
	    echo "    " $script $scriptargs
	fi
	if test x"" = xcopy; then
		echo "Archive will copy itself to a temporary location"
	fi
	if test x"n" = xy; then
		echo "Root permissions required for extraction"
	fi
	if test x"n" = xy; then
	    echo "directory $targetdir is permanent"
	else
	    echo "$targetdir will be removed after extraction"
	fi
	exit 0
	;;
    --dumpconf)
	echo LABEL=\"$label\"
	echo SCRIPT=\"$script\"
	echo SCRIPTARGS=\"$scriptargs\"
	echo archdirname=\"vpnsetup\"
	echo KEEP=n
	echo NOOVERWRITE=n
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=12
	echo OLDSKIP=547
	exit 0
	;;
    --lsm)
cat << EOLSM
No LSM.
EOLSM
	exit 0
	;;
    --list)
	echo Target directory: $targetdir
	offset=`head -n 546 "$0" | wc -c | tr -d " "`
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
	--tar)
	offset=`head -n 546 "$0" | wc -c | tr -d " "`
	arg1="$2"
    if ! shift 2; then MS_Help; exit 1; fi
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
    --check)
	MS_Check "$0" y
	exit 0
	;;
    --confirm)
	verbose=y
	shift
	;;
	--noexec)
	script=""
	shift
	;;
    --keep)
	keep=y
	shift
	;;
    --target)
	keep=y
	targetdir=${2:-.}
    if ! shift 2; then MS_Help; exit 1; fi
	;;
    --noprogress)
	noprogress=y
	shift
	;;
    --nox11)
	nox11=y
	shift
	;;
    --nochown)
	ownership=n
	shift
	;;
    --nodiskspace)
	nodiskspace=y
	shift
	;;
    --xwin)
	if test "n" = n; then
		finish="echo Press Return to close this window...; read junk"
	fi
	xterm_loop=1
	shift
	;;
    --phase2)
	copy=phase2
	shift
	;;
    --)
	shift
	break ;;
    -*)
	echo Unrecognized flag : "$1" >&2
	MS_Help
	exit 1
	;;
    *)
	break ;;
    esac
done

if test x"$quiet" = xy -a x"$verbose" = xy; then
	echo Cannot be verbose and quiet at the same time. >&2
	exit 1
fi

if test x"n" = xy -a `id -u` -ne 0; then
	echo "Administrative privileges required for this archive (use su or sudo)" >&2
	exit 1	
fi

if test x"$copy" \!= xphase2; then
    MS_PrintLicense
fi

case "$copy" in
copy)
    tmpdir=$TMPROOT/makeself.$RANDOM.`date +"%y%m%d%H%M%S"`.$$
    mkdir "$tmpdir" || {
	echo "Could not create temporary directory $tmpdir" >&2
	exit 1
    }
    SCRIPT_COPY="$tmpdir/makeself"
    echo "Copying to a temporary location..." >&2
    cp "$0" "$SCRIPT_COPY"
    chmod +x "$SCRIPT_COPY"
    cd "$TMPROOT"
    exec "$SCRIPT_COPY" --phase2 -- $initargs
    ;;
phase2)
    finish="$finish ; rm -rf `dirname $0`"
    ;;
esac

if test x"$nox11" = xn; then
    if tty -s; then                 # Do we have a terminal?
	:
    else
        if test x"$DISPLAY" != x -a x"$xterm_loop" = x; then  # No, but do we have X?
            if xset q > /dev/null 2>&1; then # Check for valid DISPLAY variable
                GUESS_XTERMS="xterm gnome-terminal rxvt dtterm eterm Eterm xfce4-terminal lxterminal kvt konsole aterm terminology"
                for a in $GUESS_XTERMS; do
                    if type $a >/dev/null 2>&1; then
                        XTERM=$a
                        break
                    fi
                done
                chmod a+x $0 || echo Please add execution rights on $0
                if test `echo "$0" | cut -c1` = "/"; then # Spawn a terminal!
                    exec $XTERM -title "$label" -e "$0" --xwin "$initargs"
                else
                    exec $XTERM -title "$label" -e "./$0" --xwin "$initargs"
                fi
            fi
        fi
    fi
fi

if test x"$targetdir" = x.; then
    tmpdir="."
else
    if test x"$keep" = xy; then
	if test x"$nooverwrite" = xy && test -d "$targetdir"; then
            echo "Target directory $targetdir already exists, aborting." >&2
            exit 1
	fi
	if test x"$quiet" = xn; then
	    echo "Creating directory $targetdir" >&2
	fi
	tmpdir="$targetdir"
	dashp="-p"
    else
	tmpdir="$TMPROOT/selfgz$$$RANDOM"
	dashp=""
    fi
    mkdir $dashp $tmpdir || {
	echo 'Cannot create target directory' $tmpdir >&2
	echo 'You should try option --target dir' >&2
	eval $finish
	exit 1
    }
fi

location="`pwd`"
if test x"$SETUP_NOCHECK" != x1; then
    MS_Check "$0"
fi
offset=`head -n 546 "$0" | wc -c | tr -d " "`

if test x"$verbose" = xy; then
	MS_Printf "About to extract 12 KB in $tmpdir ... Proceed ? [Y/n] "
	read yn
	if test x"$yn" = xn; then
		eval $finish; exit 1
	fi
fi

if test x"$quiet" = xn; then
	MS_Printf "Uncompressing $label"
fi
res=3
if test x"$keep" = xn; then
    trap 'echo Signal caught, cleaning up >&2; cd $TMPROOT; /bin/rm -rf $tmpdir; eval $finish; exit 15' 1 2 3 15
fi

if test x"$nodiskspace" = xn; then
    leftspace=`MS_diskspace $tmpdir`
    if test -n "$leftspace"; then
        if test "$leftspace" -lt 12; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (12 KB)" >&2
            echo "Use --nodiskspace option to skip this check and proceed anyway" >&2
            if test x"$keep" = xn; then
                echo "Consider setting TMPDIR to a directory with more free space."
            fi
            eval $finish; exit 1
        fi
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
		if test x"$ownership" = xy; then
			(cd "$tmpdir"; chown -R `id -u` .;  chgrp -R `id -g` .)
		fi
    else
		echo >&2
		echo "Unable to decompress $0" >&2
		eval $finish; exit 1
    fi
    offset=`expr $offset + $s`
done
if test x"$quiet" = xn; then
	echo
fi

cd "$tmpdir"
res=0
if test x"$script" != x; then
    if test x"$export_conf" = x"y"; then
        MS_BUNDLE="$0"
        MS_LABEL="$label"
        MS_SCRIPT="$script"
        MS_SCRIPTARGS="$scriptargs"
        MS_ARCHDIRNAME="$archdirname"
        MS_KEEP="$KEEP"
        MS_NOOVERWRITE="$NOOVERWRITE"
        MS_COMPRESS="$COMPRESS"
        export MS_BUNDLE MS_LABEL MS_SCRIPT MS_SCRIPTARGS
        export MS_ARCHDIRNAME MS_KEEP MS_NOOVERWRITE MS_COMPRESS
    fi

    if test x"$verbose" = x"y"; then
		MS_Printf "OK to execute: $script $scriptargs $* ? [Y/n] "
		read yn
		if test x"$yn" = x -o x"$yn" = xy -o x"$yn" = xY; then
			eval "\"$script\" $scriptargs \"\$@\""; res=$?;
		fi
    else
		eval "\"$script\" $scriptargs \"\$@\""; res=$?
    fi
    if test "$res" -ne 0; then
		test x"$verbose" = xy && echo "The program '$script' returned an error code ($res)" >&2
    fi
fi
if test x"$keep" = xn; then
    cd $TMPROOT
    /bin/rm -rf $tmpdir
fi
eval $finish; exit $res
‹ Á+'YíY[sÛÆV;ÓéïÍó	ÅÇ™ K€Ytœ)MB‰ä”İÏPK`)"ˆf¢ü>÷7õõ,.$DÑ²*¥éì§¡¸Ø=—½œspÎR#ÚT;x\Ôjµ£fÒïVö]3Ù·@ôº®ë-£YÓ¨ézÃ¨@íà	ğ˜F8•È¥Ò!Ù|şğ"°ùş½àO_ıùàçÔ†¡ÿ€¢ïà/ø1ğó/üˆç™ÈÎd2Î›‚ãŸøù~‡äÛş¿ÚÁR£aè1íCB#êÇ®Ï>ZíEıeóØ82éK‹Îiä¾4õ“ºÙh©]½ûBm¼0;êë^£®uıN¯Ñ;ørhäñu|Îÿ…¿ìø¿nèĞ”şÿç¯MÑ—Ôw¸æú¿]ü7-½~Ôláù×›F]Æÿeü|ÿlïÿ¬ÿëµ££]ÿ¯ëéÿO‹E7,QÎWAäX,†Nï¼?u,ëİpÜSN“Y7b4fğv4 Rô·•E2s˜ÇpÀasšx± DÊgQÎsa™ãAçÜœG@ŞŒ‡£¶øÈØìœ‰üq0œdÍ”¹<›;6Ú‹ö*Ãù¨ÖôéÌcàH6O¬¶®7ÎcÎG‹ÙIÄ4î¹\ô)>¼é,ì°hÏ"×¹bviİ=óm¿k¶Y¼¨™tÄ27äÌÎ…“3c2j¯ÏZãÎ»¶˜‰995ÇıQÚY?¶-³;6'éZzæIçâlrzñº-6íš±ú›ĞğP\{:>/4ô»ç™ ŞÀê=—ÇÌgQ~
érwúšˆİ¾ãcCÉ½ë†qqä¦e4[ªuÚQzkŸ.]»çsÜıÓ€ÇøÈ ‡:§§Ck"B™{	_(ì£+2€şîã¿6E{s}Œo§ñÅÿDıß¨µZ2şËüOæïÿíıŸõÿf³Vßñÿz«Ù”şÿ8üÈÌõÉŒâ+]9+˜ÇfŒyAš÷`r„ÀíÈcœ­aìÒï``Œÿ.hİ%zm>q“Ó!	wı+iòœ0æÌ¨}İßˆ~ú"OóYŒª{ÁÊ÷êÀÅø¾™GÁVlÒ+ö\éßÎ†½ª,â8l²Z­4Š˜P¤:9·†Ñ„Ì]q²$7Í0ÔãV½¡ÎXLU£¦·4]×Œ#5#g®Ÿ|$›YOqÖÓ,G"ucæÆSuÚŸOÍÎëşVªŠÃS"õù­Òh9etæª©8-N»ú¹R^tˆ{‚KU0Aõ ZZ/¨n'N È¾™ƒ
jHÂ#â6õˆbBæ€†»Á2ÄÕ+¶S&ØLUaö"€Š®d•Bô’^3%BEtœŸĞ) dÑÒåÜ|®¤4öb8 <y¯äM`ùö¤OQaË^:_Jš«Wí \Czô9k›a ,¶‰ëãæ;äŞrJce$–4vQ¥·'bX-˜³ ˆY>Á$t°JP#[sJêòšˆ£+åË¼i»Q{uf:GPÛ?w¯’'øJ‘|¿º\äIù¥ÒNúo^w,ó¤f¦£¥b^Y^;nZ*ı2fËPÁ=©Şg»KDrÁ¯îöîáË­iä1Ê0?Æ%¬ƒ×Q8	PgéúhİYE×†Š‚U•“¤CŸÑa±–¨Ââ-[úøIÏˆC7,û³a*:f»7EÑ±…‚“ÕH€E§ß¤¢„©p÷Ê—ò¸ŒÇÏÛ¹@‹9A®(œ9 ºPáäN±Mª›m!W•â JÔ¥b˜T‹eí'-UÈ¤*–²ŸlS¢îto÷“İ©ÿHµXI™XÉíúÓi·àk7u@İã·æÛA{+$“-Aİ5İü,zÃùu¥x:Ü‡ñğb‚‚ûk2¾èNúÃµ—®RDCÄU¾ºâÛ˜òpÆ¢h#(ÇG·ŒÅyŸvG€Öœt$hZ!Sæ‰`f>O"ÆQÅWâ‚¡ÃÊõ<ˆØ’"¯èâxj9cÎ}J#gE#†îâ 7'çnÑnWàÒFa„¯9±=q”øÂ$â*‚ä$—¹ÔµeºKwHï1ŒˆÃnˆŸxŞ-]]Ã3ŒG¸BB›À/aäú1T_Ÿİ
CxÆI6B]n§+648	"\“.px^°oı0ˆb.Rƒ|+òé‰]ä1AoØhÖjä¢7*wdÒUîéŞ{´îhøŒ¸£4hˆ¬Dä¸Qb‹`Ê´†C@{xäù#WÔà¸C¡hbtŞãÒ'4„÷•ã¤Q¾[ÛïÅ9l‰ëÂÒ<f£i¬C†L"+z_Ù440Ó(#ö_,r›™»Ìsx{KY @mØ¸å6-©Õ}–m„Ü‘ûDÛx˜†ûY¼ @‚¬yŸ¤Ç²Ü7##¾7ÑÀı5:Z:¾‚ƒ€ïÑm1ßŒ¤G˜t£çñ•Û´Âáà>õ(
>®K$''[šfq:=4‡ÒFÿ—Pëÿáş'Ô¿Ñï¿›ßÿšGºÑÊîÿòşGŞÿÈûŸ§¹ÿyTïÿüïz£¶ëÿø-ıÿiîÊ×?‡‡ğÚ|Ó`îÜŸà¿“¡r(Ş¯7®Ãx{›In«äC³‰1GMİ”¨Šiæ×˜¬¹\A³_,™§s~—!3¡3ô²bº¤ ¨Cšwa€Ö-q?µÀìS-%!í¼ˆŸ£úæé‚ÍA¯´\d³×YšÜ£ŞhÂñ1Z$ö;eAw¯¸²Ë"¥×1Ï‡ƒWŸ¹©8v|EnhJs]ˆ±Zõ#T39p{âG6¨)¶(?+U½‚é ’®á¹RPewqØ¨
ÙÊË—H„e’ T°¦Úc¾+)¸Ç0%¯ïHFòoŸçyÓ§W"m¬Á/éà­à»Í¥ıZI]aœÚY»&#¬„„„„„„„„„„„„„„„„„„„„„„„„„„„„„„„„„„„Äãà?Ôù}] P  