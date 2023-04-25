#!/bin/bash

Y='\e[33m'
G='\e[32m'
R='\e[31m'
M='\e[35m'
C='\e[36m'

#wc -l

help_menu(){
	echo -e "${C}Example Usage${G}: ${Y}$(basename $0) ${G}[-h] [-u] [-c] [-p] [-s] [-w] [-f] [-r] [-v] [-g]"
	echo ""
	echo -e "${G}-h             ${C}Display help menu."
	echo -e "${G}-u             ${C}Enter URL for basic WordPress enumeration."
	echo -e "${G}-c             ${C}Crawl for WordPress sites in one subnet range of IP addresses."
	echo -e "${G}-p             ${C}Path crawler that will literally look for wordpress directories in one subnet-range."
	echo -e "${G}-s             ${C}Take screenshot in one subnet-range."
	echo -e "${G}-w             ${C}Crawl URL for directories."
	echo -e "${G}-f             ${C}Insert file containing hosts to find WordPress sites."
        echo -e "${G}-r             ${C}Crawl for robots.txt files in one subnet-range"
	echo -e "${G}-v             ${C}Verbose mode for robots.txt crawling"
	echo -e "${G}-g             ${C}"
}

ascii(){
	clear
	echo ""
	echo -e "${C}██╗    ██╗ ██████╗ ██████╗ ██████╗ ███████╗██╗     ██╗"
	echo -e "${G}██║    ██║██╔═══██╗██╔══██╗██╔══██╗██╔════╝██║     ██║"
	echo -e "${C}██║ █╗ ██║██║   ██║██████╔╝██║  ██║█████╗  ██║     ██║"
	echo -e "${G}██║███╗██║██║   ██║██╔══██╗██║  ██║██╔══╝  ██║     ██║"
        echo -e "${C}╚███╔███╔╝╚██████╔╝██║  ██║██████╔╝███████╗███████╗███████╗"
	echo -e "${G} ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝╚══════╝"
	echo ""
}

while getopts ":hucpswfrvg" menu; do
	case $menu in
		h)
			ascii
			help_menu
			;;
		u)
			if [ "$EUID" -ne 0 ]; then
				ascii
				echo -e "${Y}[${C}!${Y}] ${G}Run ${Y}$(basename "$0") ${G}as root"
				exit
			fi

			trim_url_for_directory=$(echo "$2" | sed -E 's/^\s*.*:\/\///g')
			mkdir "$trim_url_for_directory" &>/dev/null
			mkdir "$trim_url_for_directory"/wordpress_results &>/dev/null
			mkdir "$trim_url_for_directory"/wordpress_loot &>/dev/null
			mkdir "$trim_url_for_directory"/web_screenshots &>/dev/null

			ascii
			echo -e "${Y}#################################################################################"
			echo -e "${Y}[${C}i${Y}] ${G}Scanning for WordPress on${Y}: ${C}$2"
			echo -e "${Y}#################################################################################"
			wordpress=$(curl -k -s "$2" | grep "WordPress")
			trim_url=$(echo "$2" | sed -E 's/^\s*.*:\/\///g')
			if [[ $wordpress ]]; then
				echo -e "${Y}[${G}+${Y}] ${G}WordPress Found${Y}: ${C}$2"
				wordpress_version=$(curl -k -s "$2" | grep 'content="WordPress' | awk '{print $4}' | tr -d '"'"'")
				if [ "$wordpress_version" ]; then
					echo -e "${Y}[${G}+${Y}] ${G}WordPress Version Found${Y}:${C} WordPress $wordpress_version"
					echo "$trim_url WordPress $wordpress_version" > "$trim_url".wordpress_version.txt
					sudo mv "$trim_url".wordpress_version.txt ./"$trim_url_for_directory"/wordpress_results
					echo "$trim_url WordPress $wordpress_version" > "$trim_url".wordpress_version.txt
					sudo mv "$trim_url".wordpress_version.txt ./"$trim_url_for_directory"/wordpress_loot
				else
					echo -e "${Y}[${R}~${Y}] ${G}WordPress Version Not Found"
				fi
				
				if wget --spider $2/wp-login.php &> /dev/null; then
					echo -e "${Y}[${G}+${Y}] ${G}Login Found${Y}:${C} $2/wp-login.php"
				else
					echo -e "${Y}[${R}~${Y}] ${G}No Login Found"
				fi

				if wget --spider $2/robots.txt &> /dev/null; then
					echo -e "${Y}[${G}+${Y}] ${G}Robots File Found${Y}:${C} $2/robots.txt"
					curl -s -k $2/robots.txt | while read -r robots; do
					echo -e "${Y}[${G}+${Y}] ${C}$robots"
				done
				else
					echo -e "${Y}[${G}~${Y}] ${G}No Robots File Found"
				fi

				echo -e "${Y}#################################################################################"
				if wget --spider $2/wp-json/wp/v2/users &> /dev/null; then
					echo -e "${Y}[${G}+${Y}] ${G}User Enum Vulnerability Found${Y}: ${C}$2/wp-json/wp/v2/users"
					check_users=$(curl -s $2/wp-json/wp/v2/users | jq -r '.[].slug')
					for users in $check_users; do
						echo -e "${Y}[${G}+${Y}] ${G}Username Found${Y}:${C} $users"
						echo "$users" >> "$trim_url".wordpress_users.txt
						sudo mv "$trim_url".wordpress_users.txt ./"$trim_url_for_directory"/wordpress_results
						echo "$users" >> "$trim_url".wordpress_users.txt
						sudo mv "$trim_url".wordpress_users.txt ./"$trim_url_for_directory"/wordpress_loot
					done
				else
					echo -e "${Y}[${R}~${Y}] ${G} User Enum Vulnerability Not Found on path /wp-json/wp/v2/users"
					echo -e "${Y}[${C}i${Y}] ${G} Trying a different approach to enumerate user names"
					wp_sitemap_users=$(curl -s "$2"/wp-sitemap.xml | xmllint --format - | grep "<loc>" | awk -F"<loc>" '{print $2} ' | awk -F"</loc>" '{print $1}')
					for list_sitemap_urls in sitemap_users; do
						author=$(echo "$list_sitemap_urls")
						if [ "$author" == "$2/wp-sitemap-users-1.xml" ]; then
							author_users=$(curl -s $2/wp-sitemap-users-1.xml | xmllint --format - | grep "<loc>" | awk -F"<loc>" '{print $2} ' | awk -F"</loc>" '{print $1}')
							for list_users_from_url in $author; do
								echo "Found possible username in url: $list_users_from_url"
							done
						fi
					done
				fi

				echo -e "${Y}#################################################################################"
				response_code=$(curl -I --silent --connect-timeout 3 "$2/wp-sitemap.xml" | grep HTTP | awk '{print $2}')
				if [ "$response_code" == "200" ]; then
					echo -e "${Y}[${G}+${Y}] ${G}wp-sitemap.xml Found${Y}: ${C}$2/wp-sitemap.xml"
					wp_sitemap_urls=$(curl -s "$2/wp-sitemap.xml" | xmllint --format - | grep "<loc>" | awk -F"<loc>" '{print $2} ' | awk -F"</loc>" '{print $1}')
					for wp_urls in $wp_sitemap_urls; do
						echo -e "${Y}[${G}+${Y}] ${G}wp-sitemap.xml${Y}: ${C}$wp_urls"
						echo "$wp_urls" >> "$trim_url".wordpress_sitemap_urls.txt
						sudo mv "$trim_url".wordpress_sitemap_urls.txt ./"$trim_url_for_directory"/wordpress_results
						echo "$wp_urls" >> "$trim_url".wordpress_sitemap_urls.txt
						sudo mv "$trim_url".wordpress_sitemap_urls.txt ./"$trim_url_for_directory"/wordpress_loot
					done
                                echo -e "${Y}#################################################################################"
				else
					echo -e "${Y}[${R}~${Y}] ${G}wp-sitemap.xml Not Found"
                                        echo -e "${Y}#################################################################################"
				fi
			else
				echo -e "${Y}[${R}~${Y}] ${G}WordPress Not Found: $2"
				echo -e "${Y}[${M}!${Y}] ${G}Aborting the script"
				echo -e "${Y}[${M}!${Y}] ${G}Have a nice day :)"
			fi
			;;
		c)
			ascii
			echo -e "${Y}#################################################################################"
			echo -e "${Y}[${C}i${Y}] ${G}Scanning for WordPress in one range${Y}: ${C}$2/24"
			echo -e "${Y}#################################################################################"
                        echo ""
			list_http_server_range=$(echo "$2/24" | httpx -silent)
			for crawl_subnet in $list_http_server_range; do
				if curl -s -k --connect-timeout 3 "$crawl_subnet" | grep "WordPress" &>/dev/null; then
					echo -e "${Y}[${G}+${Y}] ${G}$crawl_subnet ${Y}: ${G}Found WordPress"
				else
					echo -e "${Y}[${R}~${Y}] ${R}$crawl_subnet ${Y}: ${R}WordPress Not Found"
				fi
			done
			;;
		p)
			ascii
			path=("wp-login wp-sitemap.xml")
			for paths in $path; do
				list_http_server_range=$(echo "$2/24" | httpx -silent)
				for crawl_subnet in $list_http_server_range; do
					all_paths=$(echo "$crawl_subnet/$paths")
					response_code=$(curl -k -I --silent --connect-timeout 3 "$all_paths" | grep HTTP | awk '{print $2}')
					if [ "$response_code" == "200" ]; then
						echo -e "${Y}[${G}+${Y}] ${G}$all_paths ${Y}: ${G}Found"
					else
						echo -e "${Y}[${R}~${Y}] ${R}$all_paths ${Y}: ${R}Not Found"
					fi
				done
			done
			;;
		s)
			if [ $EUID -ne 0 ]; then
				echo "[!] Run $(basename "$0") as root"
				exit
			fi

                        trim_url_for_directory=$(echo "$2" | sed -E 's/^\s*.*:\/\///g')
			mkdir "$trim_url_for_directory" &>/dev/null
                        mkdir "$trim_url_for_directory"/wordpress_results &>/dev/null
                        mkdir "$trim_url_for_directory"/wordpress_loot &>/dev/null
                        mkdir "$trim_url_for_directory"/web_screenshots &>/dev/null

			list_http_server_range=$(echo "$2/24" | httpx -silent)
			for crawl_subnet in $list_http_server_range; do
				response_code=$(curl -I --silent --connect-timeout 3 "$crawl_subnet" | grep HTTP | awk '{print $2}')
				if [ "$response_code" == "200" ]; then
					echo -e "${Y}[${G}+${Y}] ${G}Taking screenshot of ${Y}$crawl_subnet"
                                        trim_url=$(echo "$crawl_subnet" | sed -E 's/^\s*.*:\/\///g')
					wkhtmltoimage -q "$crawl_subnet" "$trim_url".png &>/dev/null ||  cutycapt --url="$crawl_subnet" --out="$trim_url".png
					sudo mv "$trim_url".png ./"$trim_url_for_directory"/web_screenshots
				fi
			done
			;;
		w)
			while read -r crawl; do
				target=$2
				response_code=$(curl -I --silent --connect-timeout 3 "$target"/"$crawl" | grep HTTP | awk '{print $2}')
				if [ "$response_code" == "200" ]; then
					echo -e "${Y}[${G}+${Y}] ${G}$target/$crawl ${Y}: ${G}Found"
				fi
			done < /usr/share/wordlists/dirb/common.txt
			;;
		f)
                        ascii
                        echo -e "${Y}#################################################################################"
                        echo -e "${Y}[${C}i${Y}] ${G}Scanning for WordPress in${Y}: ${C}$2/24"
                        echo -e "${Y}#################################################################################"
                        echo ""
			cat $2 | while read wordpress_hosts; do
			httpx -silent $wordpress_hosts | while read wordpress_http; do
			if [ $(curl -s --connect-timeout 3 $wordpress_http | grep "WordPress") ]; then
				echo "Found WordPress: $wordpress_http"
			else
				echo "Wordpress not found: $wordpress_http"
			fi
		done
	done
			;;
		r)
			subnet=$(echo "$2/24" | httpx -silent)
			for data in $subnet; do
				response=$(curl -k --silent --connect-timeout 3 "$data/robots.txt" | grep HTTP | awk '{print $2}')
				if [ "$response" == "200" ]; then
					echo "Found: $data/robots.txt"
					while getopts ":v" menu_2; do
						case $menu_2 in
							v)
								curl -k --silent --connect-timeout 3 "$data/robots.txt"
						esac
					done
				else
					echo "No: $data"
				fi
			done
			;;
		v)
			subnet=$(echo "$2/24" | httpx -silent)
			for data in $subnet; do
				response=$(curl -IL -k --silent --connect-timeout 3 "$data/robots.txt" | grep HTTP | awk '{print $2}')
				if [ "$response" == "200" ]; then
					echo ""
					echo "Found: $data/robots.txt"
					curl -k --silent --connect-timeout 3 $data/robots.txt
					echo ""
				else
					echo "No: $data"
				fi
			done
			;;
			g)
				trap 'rm global.txt || echo "" &>/dev/null ; rm count.txt || echo "" &>/dev/null; exit' INT
				bash wordell_config_file_for_global_ip_scan.sh > global.txt
				cat global.txt | while read parse_addreses; do
                                country=$(curl -s ipinfo.io/$parse_addreses | jq ".country" | sed -e "s/\"//g" -e "s/\"/'/g")
                                city=$(curl -s ipinfo.io/$parse_addreses | jq ".city" | sed -e "s/\"//g" -e "s/\"/'/g")
				echo "[Country] $country [City] $city [IP] $parse_addreses"
				echo "[Country] $country [City] $city [IP] $parse_addreses" >> count.txt
			done
			echo ""
			count=$(cat count.txt | wc -l)
			echo "[i] Found $count results"
			rm global.txt
			rm count.txt
			;;
		\?)
			ascii
			help_menu
			;;
	esac
done
