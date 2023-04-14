#!/bin/bash

Y='\e[33m'
G='\e[32m'
R='\e[31m'
M='\e[35m'
C='\e[36m'

help_menu(){
	echo -e "${C}Example Usage${G}: ${Y}$(basename $0) ${G}[-h] [-u] [-c] [-p]"
	echo -e "${G}-h       ${C}Display help menu."
	echo -e "${G}-u       ${C}Enter URL."
	echo -e "${G}-c       ${C}Crawl for WordPress sites in one subnet range of IP addresses."
	echo -e "${G}-p       ${C}Path crawler that will literally look for wordpress directories in one subnet-range"
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

while getopts ":hucpsw" menu; do
	case $menu in
		h)
			ascii
			help_menu;;
		u)
			if [ "$EUID" -ne 0 ]; then
				ascii
				echo "[!] Run $(basename $0) as root"
				exit
			fi

			trim_url_for_directory=$(echo "$2" | sed -E 's/^\s*.*:\/\///g')
			mkdir $trim_url_for_directory &>/dev/null
			mkdir $trim_url_for_directory/wordpress_results &>/dev/null
			mkdir $trim_url_for_directory/wordpress_loot &>/dev/null
			mkdir $trim_url_for_directory/wordpress_screenshots &>/dev/null

			ascii
			echo -e "${Y}[${C}i${Y}] ${G}Scanning for WordPress on${Y}: ${C}$2"
			echo ""
			wordpress=$(curl -s $2 | grep "WordPress")
			trim_url=$(echo "$2" | sed -E 's/^\s*.*:\/\///g')
			if [[ $wordpress ]]; then
				echo -e "${Y}[${G}+${Y}] ${G}WordPress Found${Y}: ${C}$2"
				wordpress_version=$(curl -s $2 | grep 'content="WordPress' | awk '{print $4}' | tr -d '"'"'")
				if [ $wordpress_version ]; then
					echo -e "${Y}[${G}+${Y}] ${G}WordPress Version Found${Y}:${C} WordPress $wordpress_version"
					echo "$trim_url WordPress $wordpress_version" > $trim_url.wordpress_version.txt
					sudo mv $trim_url.wordpress_version.txt ./$trim_url_for_directory/wordpress_results
					echo "$trim_url WordPress $wordpress_version" > $trim_url.wordpress_version.txt
					sudo mv $trim_url.wordpress_version.txt ./$trim_url_for_directory/wordpress_loot
				else
					echo -e "${Y}[${R}~${Y}] ${G}WordPress Version Not Found"
				fi

				echo -e "${Y}--------------------------------------------------------------------------------------------"
				if wget --spider $2/wp-json/wp/v2/users &> /dev/null; then
					echo -e "${Y}[${G}+${Y}] ${G}User Enum Vulnerability Found${Y}: ${C}$2/wp-json/wp/v2/users"
					check_users=$(curl -s $2/wp-json/wp/v2/users | jq -r '.[].slug')
					for users in $check_users; do
						echo -e "${Y}[${G}+${Y}] ${G}Username Found${Y}:${C} $users"
						echo "$users" >> $trim_url.wordpress_users.txt
						sudo mv $trim_url.wordpress_users.txt ./$trim_url_for_directory/wordpress_results
						echo "$users" >> $trim_url.wordpress_users.txt
						sudo mv $trim_url.wordpress_users.txt ./$trim_url_for_directory/wordpress_loot
					done
				else
					echo -e "${Y}[${R}~${Y}] ${G} User Enum Vulnerability Not Found"
				fi

				echo -e "${Y}--------------------------------------------------------------------------------------------"
				if wget --spider $1/wp-sitemap.xml &> /dev/null; then
					echo -e "${Y}[${G}+${Y}] ${G}wp-sitemap.xml Found${Y}: ${C}$2/wp-sitemap.xml"
					wp_sitemap_urls=$(curl -s $2/wp-sitemap.xml | xmllint --format - | grep "<loc>" | awk -F"<loc>" '{print $2} ' | awk -F"</loc>" '{print $1}')
					for wp_urls in $wp_sitemap_urls; do
						echo -e "${Y}[${G}+${Y}] ${G}wp-sitemap.xml${Y}: ${C}$wp_urls"
						echo "$wp_urls" >> $trim_url.wordpress_sitemap_urls.txt
						sudo mv $trim_url.wordpress_sitemap_urls.txt ./$trim_url_for_directory/wordpress_results
						echo "$wp_urls" >> $trim_url.wordpress_sitemap_urls.txt
						sudo mv $trim_url.wordpress_sitemap_urls.txt ./$trim_url_for_directory/wordpress_loot
					done
				else
					echo -e "${Y}[${R}~${Y}] ${G}wp-sitemap.xml Not Found"
				fi
			else
				echo -e "${Y}[${R}~${Y}] ${G}WordPress Not Found: $2"
				echo -e "${Y}[${M}!${Y}] ${G}Aborting the script"
				echo -e "${Y}[${M}!${Y}] ${G}Have a nice day :)"
			fi
			;;
		c)
			ascii
			list_http_server_range=$(echo "$2/24" | httpx -silent)
			for crawl_subnet in $list_http_server_range; do
				if curl -s --connect-timeout 3 $crawl_subnet | grep "WordPress" &>/dev/null; then
					echo -e "${Y}[${G}+${Y}${Y}] ${G}$crawl_subnet ${Y}: ${G}Found WordPress"
				else
					echo -e "${R}[${R}~${Y}] ${R}$crawl_subnet ${Y}: ${R}WordPress Not Found"
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
					response_code=$(curl -I --silent --connect-timeout 3 $all_paths | grep HTTP | awk '{print $2}')
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
				echo "[!] Run $(basename $0) as root"
				exit
			fi

                        trim_url_for_directory=$(echo "$2" | sed -E 's/^\s*.*:\/\///g')
			mkdir $trim_url_for_directory &>/dev/null
                        mkdir $trim_url_for_directory/wordpress_results &>/dev/null
                        mkdir $trim_url_for_directory/wordpress_loot &>/dev/null
                        mkdir $trim_url_for_directory/wordpress_screenshots &>/dev/null

			list_http_server_range=$(echo "$2/24" | httpx -silent)
			for crawl_subnet in $list_http_server_range; do
				response_code=$(curl -I --silent --connect-timeout 3 $crawl_subnet | grep HTTP | awk '{print $2}')
				if [ "$response_code" == "200" ]; then
					echo -e "${Y}[${G}+${Y}] ${G}Taking screenshot of ${Y}$crawl_subnet"
					trim_url=$(echo "$crawl_subnet" | sed -E 's/^\s*.*:\/\///g')
					wkhtmltoimage -q $crawl_subnet $trim_url.png &>/dev/null ||  cutycapt --url=$crawl_subnet --out=$trim_url.png
					sudo mv $crawl_subnet.png ./$trim_url_for_directory/wordpress_screenshots
				fi
			done
			;;
		w)
			while read crawl; do
				target=$2
				response_code=$(curl -I --silent --connect-timeout 3 $target/$crawl | grep HTTP | awk '{print $2}')
				if [ "$response_code" == "200" ]; then
					echo -e "${Y}[${G}+${Y}] ${G}$target/$crawl ${Y}: ${G}Found"
				fi
			done < /usr/share/wordlists/dirb/common.txt
			;;
		\?)
			ascii
			help_menu
			;;
	esac
done
