#!/bin/bash
### Hacker News Web Scraper by Jasbir Khosa
# Script to scrape articles from Hacker News
# Scan heading for key words and color codes indexed list
# Allow user to choose and download indexed articles
# Allow user to create a customised keyword list
# Revision date
# created (5/6/21)
# added text scanning (7/6/21)
# added show all/keywords only (8/6/21)
# added keyword customiser (9/6/21)

### Functions
# capture webpage
function capture_webpage() {
        for ((i=1;i<=$1;i++));do
                webp="$url$i"
                echo $webp
                curl -o temp.txt $webp &>/dev/null
                down_errors
                cat temp.txt >> temp1.txt
              
        done
}

# parse webpage
function parse_html() {
        grep "" temp1.txt | sed -e ' />Hacker News</ d; />Guidelines</ d; />login/ d; />More/ d;s/<[^>]*>//g; /|/ d' > temp2.txt
        grep "" temp2.txt | sed -e ' /^$/ d; /^\s\s*$/ d; /)$/ !d' > article.txt
        cat temp1.txt | grep -Eo '\b(http|https)://.*\" |href="item.*[1-9]*\" class=' | sed -e 's/".*//g; /news\.ycombinator/ d; /com\/HackerNews\/API/ d; /ycombinator\.com\/legal/ d; /ycombinator\.com\/apply/ d' > http.txt
}

# clean up temporary files
function clean_files() {
        rm article.txt temp.txt temp1.txt temp2.txt 2> /dev/null
}

# downloading errors and clean up on exit
function down_errors() {
        if [ $? -ne 0 ]; then
                echo -e "\033[31mSorry there was a problem downloading the page..."
                echo -e "Please check network connection or try again later...\033[0m"
                clean_files
                exit -1
        fi
}

# address other errors and clean up on exit
function catch_err() {
        if [ $? -eq 130 ]; then
                echo "Error downloading page..."
                clean_files
                exit -1
        elif [ $? -ne 1 ]; then
                echo "$? error detected..."
                clean_files
                exit -1
        fi
}

# list artilces with option for display all headings or keyword list only 
function list_articles() {
        clear
        art_num=1
        let " art_num = page_num * 30"
        IFS=$'\n'
        full_file=$(cat article.txt)
        title_full=($full_file)
        title_file=$(cat article.txt | sed 's/[0-9]*\.\s\s\s\s\s\s//g')
        title_words=($title_file)

        if [ $show_all -eq 1 ]; then    
            echo "Indexed list only showing article headings with keywords."
            echo
        else
            echo "Indexed list showing all article headings."
            echo
        fi

        word_count=0
        for ((x=0;x<$art_num;x++)); do
            test1="${title_words[$x]}"
            tfull="${title_full[$x]}"
            count=0
            IFS=" "

            for j in ${cswords[@]}; do
                match="s/$j//gI"
                pmatch=$(echo "$test1" | sed -E $match)       
                
                if [ ! "$test1" == "$pmatch" ] ; then
                        let " count = count + 1 "
                        let " word_count = word_count + 1 " 
                fi
            done

            if [ $count -eq 0 ]; then
                if [ $show_all -eq -1 ]; then
                        echo -e "\033[32m$tfull\033[0m"
                fi
            else
                echo -e "\033[31m$tfull\033[0m"
            fi            
        done

}

### Initialisation
trap "catch_err" ERR

# check folder permission
touch temp.txt
if [ ! -w temp.txt ]; then
    clear
    echo -e "\033[31m***Hacker News Web Scraper requires write permission in the current folder.***\033[0m"
    echo -e "Please place HNWS in a folder that allows write permission."
    echo
    exit 0
fi

# stop buffer overflow attack
if [ $(stat -c %s "keywords.txt") -gt 550 ]; then
    echo -e "\033[31mThe keywords file has been corrupted and will be replaced.\033[0m"
    sleep 3
    rm keywords.txt
fi

# array of keywords from file or default
if [ -f keywords.txt ]; then
    IFS=$' '
    wordf=$(cat keywords.txt)
    cswords=($wordf)
else
    cswords="cyber security hack hash icloud password privacy http server ransom IoT ddos html iOS macOS zero secret spy email"
    echo "${cswords[@]}" > keywords.txt
fi

# setup url to Hacker News and leave page number empty
url="https://news.ycombinator.com/news?p="


##### MAIN SCRIPT ####

# clear old text files if present
if [ -f article.txt ]; then
    clean_files
fi

# intro to webscraper script
word_limit=50
clear
echo -e "\033[34mHacker News Web Scraper by Jasbir Khosa (5/6/21)\033[0m"
echo -e "\033[32mThis script scrapes a list of article headings from Hacker News pages (https://news.ycombinator.com/).\033[0m"
echo -e "\033[32mThe script scans and colour codes the headings based on a list of keywords.\033[0m"
echo -e "\033[32mThe user can customise keywords, review headings and select articles to download.\033[0m"
echo -e "\033[32mThe text file keywords.txt is created to store the customised keyword list (maximum of $word_limit words).\033[0m"

# customise keywords list
echo
test=0
resp=n
while [ $test -eq 0 ]; do
        
        echo
        echo -e "\033[32mThe current keywords are:"
        cat keywords.txt | xargs -n 1 | sort | xargs
        echo -e "\033[0m"
        read -p "Do you want to add(a) or delete(d) any keywords? next(n) menu: " resp

        if [ "${resp,,}" == "a" ] ; then
                if [ $word_limit -le ${#cswords[@]} ]; then
                        echo -e "\033[31mThe keywords limit of $word_limit words has been reached."
                        echo -e "Please delete a word before adding a new word."
                        echo -e "\033[0m"
                else
                        echo
                        read -p "Please enter a keyword to add (x to exit): " resp

                        if [ ! "${resp,,}" == "x" ]; then
                               
                                cswords[${#cswords[@]}]="$resp"
                                echo "${cswords[@]}" > keywords.txt
                                echo
                        fi
                fi


        elif [ "${resp,,}" == "d" ]; then

                echo
                read -p "Please enter a keyword to delete (x to exit): " resp
                word_check=0
                for i in ${cswords[@]}; do
                        if [ $i == $resp ]; then
                                word_check=1
                        fi
                done
                if [ $word_check -eq 0 ]; then
                        echo -e "\033[31m$resp is not in the keyword list and can not be deleted.\033[0m"
                else
                        if [ ! "${resp,,}" == "x" ] ; then
                                pmatch="s/$resp//gI"
                                echo "${cswords[@]}" | sed -E $pmatch > keywords.txt
                                IFS=$' '
                                wordf=$(cat keywords.txt)
                                cswords=($wordf)
                        fi
                fi
        elif [ "${resp,,}" == "n" ]; then
                test=1
        else
                echo -e "\033[31mPlease specify add (a) or delete (d) or exit (n) only.\033[0m" 
        fi
done

# select show all headings or keyword only headings
test=0
show_all=-1
resp=n
while [ $test -eq 0 ]; do
        echo
        read -p "Do you want to see keyword only article headings (y/n): " resp
        if [ "${resp,,}" == "y" ] ; then
                test=1
                show_all=1
        elif [ "${resp,,}" == "n" ] ; then
                test=1
        else
                echo -e "\033[31mPlease specify yes (y) or no (n) only.\033[0m" 
        fi
done

# get the number of pages to scrape
test=0
page_num=1
clear
while [ $test -eq 0 ]; do
        echo
        read -p "Please specify the number of pages to scrape (1-10): " page_num

        if echo "$page_num" | grep -vqE '^[0-9]+$'; then
                echo -e "\033[31mPlease specify a number from 1 to 10.\033[0m" 
        elif [ $page_num -gt 0 ] && [ $page_num -lt 11 ]; then
                test=1
        else
                echo -e "\033[31mPlease specify a number from 1 to 10.\033[0m" 
        fi
done
cd ~/Student/Script/Assignment

# run the webscraper 
capture_webpage $page_num
parse_html

# print indexed list of article headings
list_articles

# select article and download with default browser
word_stat=0
test=0
ch_num=1
let word_stat=" 100 * word_count / art_num "
while [ $test -eq 0 ]; do
        echo
        echo -e "\033[31m$word_stat% of articles have a keyword in the heading.\033[0m"
        read -p "Please specify the number of the article to download (1-$art_num, 0 to exit, -1 to toggle list): " ch_num

        if echo "$ch_num" | grep -vqE '^[-0-9]+$'; then
                echo -e "\033[31mPlease specify a number greater than 0 and up to $art_num.\033[0m" 
        elif [ $ch_num -gt 0 ] && [ $ch_num -le $art_num ]; then
                art_file=$(cat  http.txt |tr "\n" " ")
                art_http=($art_file)
                let "ch_num = ch_num - 1"
                xdg-open "${art_http[$ch_num]}"
                down_errors
                sleep 8
        elif [ $ch_num -eq 0 ]; then
                echo "Goodbye......"
                clean_files
                exit 0
        elif [ $ch_num -eq -1 ]; then
                let "show_all = show_all * -1"
                list_articles
        else
                echo -e "\033[31mPlease specify a number greater than 0 and up to $art_num.\033[0m" 
        fi
done

### end of script
exit 0