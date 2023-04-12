#!/bin/bash

Y='\e[33m'
G='\e[32m'
R='\e[31m'
M='\e[35m'
C='\e[36m'

help_menu(){
	echo "Example Usage: $(basename $0) [-h] [-d] [-c]"
	echo "-h       Display help menu."
	echo "-u       Enter URL."
	echo "-c       Crawl for WordPress sites in one subnet range of IP addresses."
}

while getopts ":huc" option; do
   case $option in
      h)
	      help_menu;;
      u)
	      clear
	      echo ""
	      echo -e "${C}██╗    ██╗ ██████╗ ██████╗ ██████╗ ███████╗██╗     ██╗"
	      echo -e "${G}██║    ██║██╔═══██╗██╔══██╗██╔══██╗██╔════╝██║     ██║"
	      echo -e "${C}██║ █╗ ██║██║   ██║██████╔╝██║  ██║█████╗  ██║     ██║"
	      echo -e "${G}██║███╗██║██║   ██║██╔══██╗██║  ██║██╔══╝  ██║     ██║"
	      echo -e "${C}╚███╔███╔╝╚██████╔╝██║  ██║██████╔╝███████╗███████╗███████╗"
	      echo -e "${G} ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝╚══════╝"
	      echo ""
	      echo -e "${Y}[${C}i${Y}] ${G}Scanning for WordPress on${Y}: ${C}$2"
	      echo ""
	      wordpress=$(curl -s $2 | grep "WordPress")
	      if [[ $wordpress ]]; then
		      echo -e "${Y}[${G}+${Y}] ${G}WordPress Found${Y}: ${C}$2"
		      wordpress_version=$(curl -s $2 | grep 'content="WordPress' | awk '{print $4}' | tr -d '"'"'")
		      if [ $wordpress_version ]; then
			      echo -e "${Y}[${G}+${Y}] ${G}WordPress Version Found${Y}:${C} WordPress $wordpress_version"
		      else
			      echo -e "${Y}[${R}~${Y}] ${G}WordPress Version Not Found"
		      fi
		      
		      echo -e "${Y}--------------------------------------------------------------------------------------------"
		      if wget --spider $2/wp-json/wp/v2/users &> /dev/null; then
			      echo -e "${Y}[${G}+${Y}] ${G}User Enum Vulnerability Found${Y}: ${C}$2/wp-json/wp/v2/users"
			      check_users=$(curl -s $2/wp-json/wp/v2/users | jq -r '.[].slug')
			      for users in $check_users; do
				      echo -e "${Y}[${G}+${Y}] ${G}Username Found${Y}:${C} $users"
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
	      subnet_range=$(echo "$2/24" | httpx -silent)
	      for crawl_subnet in $subnet_range; do
		      if curl -s --connect-timeout 3 $crawl_subnet | grep "WordPress" &>/dev/null; then
			      echo -e "${C}[+] $crawl_subnet : Found WordPress"
		      else
			      echo -e "${R}[~] $crawl_subnet : WordPress Not Found"
		      fi
	      done
esac
done
