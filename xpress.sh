#!/bin/bash

### By: Argon3x
### Supported: Debian Based Systems, and Termux
### Version: 2.0

export IFS='
'

# colors
red="\033[01;31m"; green="\033[01;32m"; blue="\033[01;34m"; yellow="\033[01;33m";
purple="\033[01;35m"; grey="\033[01;30m"; end="\033[00m";

# symbol
box="\033[01;35m[\033[01;32m+\033[01;35m]\033[00m"

# error function and cancel
ctrl_c(){
  echo -e "\n${blue}>>> ${red}Cancelled Process ${blue}<<<${end}\n"
  tput cnorm
  exit 1
}

error(){
  local typeError="$1"
  echo -e "\n${red}Error${end}: ${typeError}\n"
  tput cnorm
  exit 1
}

# calling signal
trap ctrl_c SIGINT
trap error SIGTERM


# help menu
help_menu(){
  clear
  local script=${0##*/}
  local name=$(echo $script | awk -F '[-]' '{print $1}')

 echo -e "${purple}---------------------------------------${end}"
 echo -e "${green} ${name}${end}\n"
 echo -e "${blue} -d\t\t${purple}Select a Directory${end}" 
 echo -e "${blue} -h, --help\t${purple}Show the help menu${end}\n"
 echo -e "${green} use: ${purple}xpress -d <path directory>${end}"
 echo -e "${purple}---------------------------------------${end}"
 exit 0
}

# check dependencies function
check_dependencies(){
  local readonly path_dependencies="/usr/bin"
  local readonly dependencies=(unrar unzip)
  local count=0

  for i in ${dependencies[@]}; do
    `test -f "${path_dependencies}/${i}"`
    if [[ $? -eq 0 ]]; then
      let count+=1
    fi
  done

  if [[ ${count} -eq 2 ]]; then
    return 0
  else
    error "${yellow}Dependencies error, check the necessary dependencies ${blue}(${yellow}unzip, unrar${blue})${end}"
  fi
}

# function that unpack rar files
unpack_rars(){
  local path_directory_rar="$1"

  # create the rar directory, to store the decompressed files
  echo -e "${box} ${yellow}Creating ${green}rar ${yellow}directory.......${end}\c"; sleep 0.6
  `mkdir ${path_directory_rar}/rar_files 2>/dev/null`

  if [[ $? -eq 0 ]]; then
    echo -e "${green} done ${end}"
  else
    echo -e "${red} failed ${end}"
    error "${blue}An error occurred while creating the ${red}rar ${blue}directory${end}"
  fi

  # unpack the rar files
  local path_save="${path_directory_rar}/rar_files"
  echo -e "${box} ${yellow}Unpacking ${green}${2} ${yellow}rar file(s).......${end}"; sleep 1

  # check if the file is not corrupted
  for i in ${path_directory_rar}/*.rar; do
    `unrar t ${i} > /dev/null 2>&1`
    if [[ $? -eq 0 ]]; then
      # unpacking rar files
      local save_directory="${path_save}/${i##*/}"
      echo -e "${box} ${purple}Unpacking ${green}${i} ${purple}to ${grey}${save_directory%.*}${end}\c"
      `mkdir ${save_directory%.*} && unrar x ${i} ${save_directory%.*} >/dev/null 2>&1`
      
      # check errors
      if [[ $? -eq 0 ]]; then
        echo -e "${green} done ${end}"
      else
        echo -e "${red} failed ${end}"
        error "${blue}An error occurred while decompressing the file ${red}${i##*/}"
      fi 
    else
      error "${blue}the ${red}${i##*/} file is corrupted${end}"
    fi
  done
}

# function that unpack zip files 
unpack_zips(){
  local path_directory_zip="$1"

  # create the zip directory, to store the decompressed files
  echo -e "\n${box} ${yellow}Creating ${green}zip ${yellow}directory.......${end}\c"; sleep 0.6
  `mkdir ${path_directory_zip}/zip_files 2>/dev/null`

  if [[ $? -eq 0 ]]; then
    echo -e "${green} done ${end}"
  else
    echo -e "${red} failed ${end}"
    error "${blue}An error occurred while creating the ${red}zip ${blue}directory${end}"
  fi

  # unpacking the zip files
  local path_save="${path_directory_zip}/zip_files"
  echo -e "${box} ${yellow}Unpacking ${green}${2} ${yellow}zip file(s).......${end}"; sleep 1
  
  # check if the file is not corrupted
  for i in ${path_directory_zip}/*.zip; do
    `unzip -t -qq ${i} 2>/dev/null`

    if [[ $? -eq 0 ]]; then
      # unpacking zip files
      local save_directory="${path_save}/${i##*/}"
      echo -e "${box} ${purple}Unpacking ${green}${i} ${purple}to ${grey}${save_directory%.*}${end}\c"
      `unzip -qq ${i} -d ${save_directory%.*} 2>/dev/null`
      
      # check errors
      if [[ $? -eq 0 ]]; then
        echo -e "${green} done ${end}"
      else
        echo -e "${red} failed ${end}"
        error "${blue}An error occurred while decompressing the file ${red}${i##*/}"
      fi
    else
      error "${blue}the ${red}${i##*/} file is corrupted${end}"
    fi
  done 
}

# main function
main(){
  local directory="$1"
  
  # call the check dependencies function
  check_dependencies

  # check if the path ends with a slash
  [[ ${directory: -1} == '/' ]] && local directory=${directory%?}

  # check if the directory exist 
  echo -e "${box} ${yellow}Checking if the directory exist.......${end}\c"; sleep 0.4
  if [[ -d ${directory} ]]; then
    echo -e "${green} done ${end}"
  else
    echo -e "${red} failed ${end}"
    error "${yellow}the directory ${red}${directory} ${yellow}does not exist${end}"
  fi

  # check if files exist (rar, zip)
  local rar=$(command ls ${directory}/*.rar 2>/dev/null | wc -l)
  local zip=$(command ls ${directory}/*.zip 2>/dev/null | wc -l)

  # call the function to decompress the files (rar,zip)
  if [ $(expr $rar + $zip) -ne 0 ]; then
    tput civis
    # call the unpack rars function
    if [[ ${rar} -ne 0 ]]; then
      unpack_rars "${directory}" "${rar}"
    fi

    # call the unpack zips function
    if [[ ${zip} -ne 0 ]]; then
      unpack_zips "${directory}" "${zip}"
    fi
    tput cnorm
  else
    echo -e "\n${grey} $(expr $rar + $zip) ${yellow}files ${blue}(${yellow}rar, zip${blue})${end}\n"
  fi
}


# checking parameters
if [[ $# -eq 2 ]]; then
  # get the valie of the parameters
  while getopts ":d:" args; do
    case $args in
      d) path_directory=$OPTARG ;;
      \?) echo -e "${blue}the option ${red}-${OPTARG} ${blue}is not valid, use -h or --help for more help${end}" ;;
    esac
  done
  
  # check that the variable is not null
  if [[ -n ${path_directory} ]]; then
    main "${path_directory}"
  fi
else
  help_menu
fi
