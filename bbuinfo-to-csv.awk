#!/usr/bin/awk -f
BEGIN 	{ ORS = "," }
	/ial\ N/        { print $4 }
	/ck\ En/	{
				outstring = ($3>288) ? "PASS " : "FAIL ";
				outstring = outstring "/ " $3 $4 
			}
	/Capaci/	{ outstring = outstring " C" $2 $3 }
	/rve\ S/	{ outstring = outstring " R" $4 }
END 	{ 
		ORS = "\n";
		print outstring
	}
