#!/bin/bash

#Parameter
keys=()
names=()
dates=()
qualityGates=()
revisions=()

url=""
token=""
username=""
password=""

return_type=""
json=""

directory=$(pwd)

#Function to save and check credential for sonarqube
function check_credential_file() {

    if [[ -f "./.credentials" ]]; then
        echo ""
        # echo "It is stored in $1/.credentials"
    else 
        echo "Please run command ./script.sh -c to setup" 
        exit 1
    fi
}

function save_credential_file() {

    if [[ -f "./.credentials" ]]; then
        echo "Credential file already exists."
        echo ""
        exit 1
    fi

    get_sonar "$directory"
    echo "Please choose an option for saving credential:[Enter 1 or 2]"
    echo "1. Token"
    echo "2. Username/Password"
        read -r option
        if [[ $option == "1" ]]; then
            get_token "$directory"
        elif [[ $option == "2" ]]; then
            get_username_password "$directory"
        else
            echo "Invalid option. Exiting."
            exit 1
        fi
}

function get_token() {
    echo "Please enter your token:[Same as analysis token]"
    read -r token
    echo "Token:$token" >> "$1/.credentials"
    echo "Token stored in $1/.credentials"
}
# Function to prompt the user to input a username and password
function get_username_password() {
    echo "Please enter your username:"
    read -r username
    echo "Please enter your password:"
    read -rs password
    echo "Username:$username" >> "$1/.credentials"
    echo "Password:$password" >> "$1/.credentials"
    echo "Credentials stored in $1/.credentials"
}

function get_sonar() {
    echo "Please enter sonarqube server url:[Enter nothing, Default: https://ft83.primecredit.com/sonarqube/]"
    read -r sonar_url
    if [ -z "$sonar_url" ]; then
        echo "Url:https://ft83.primecredit.com/sonarqube/" > "$1/.credentials"
    else
        echo "Url:$sonar_url" > "$1/.credentials"
    fi    
    echo "Url stored in $1/.credentials"
}


#Function to set sonarqube url from credential
function set_sonar_url() {
    while IFS= read -r line || [[ -n "$line" ]]; do

        if [[ "$line" = "Url:"* ]];then
            url=$(echo "$line" | awk -F 'l:\\s*' '/Url/ {print $2}')
        fi

        if [[ "$line" = "Username:"* ]];then
            username=$(echo "$line" | awk -F ':\\s*' '/Username/ {print $2}')

        fi

        if [[ "$line" = "Password:"* ]];then
            password=$(echo "$line" | awk -F ':\\s*' '/Password/ {print $2}')
        fi

        if [[ "$line" = "Token:"* ]];then
            token=$(echo "$line" | awk -F ':\*' '/Token:/ {print $2}')
        fi

    done < "$directory/.credentials"

}

#Function to return check credential type
function return_credential_type() {
    if [[ "$token" = "" ]];then
        return_type="unpw"
    else
        return_type="token"
    fi
}

#Function to delete credential file
function remove_credential_file() {
    rm -f $directory/.credentials
    echo "Credentials deleted"
}

#Function to get project info from SonarQube API
function list_project_info() {
    check_credential_file $directory

    set_sonar_url
    return_credential_type
    # JSON data
    get_project_info_from_api

    # Print the extracted data
    for ((i=0; i<${#keys[@]}; i++)); do
        echo "Project $((i+1)): "
        echo "Key: ${keys[i]}"
        echo "Name: ${names[i]}"
        echo "Last Analysis Date: ${dates[i]}"
        echo "Quality Gate: ${qualityGates[i]}"
        echo "Revision: ${revisions[i]}"
        echo
    done
}


function search_project_by_name() {
    check_credential_file $directory
    local search_name="$1"

    set_sonar_url
    return_credential_type
    # JSON data
    get_project_info_from_api
    
    # Print the extracted data
    for ((i=0; i<${#keys[@]}; i++)); do
        if [[ "${names[i]}" == "$search_name" ]]; then
            # echo "Project $((i+1)): "
            echo "Key: ${keys[i]}"
            echo "Name: ${names[i]}"
            echo "Last Analysis Date: ${dates[i]}"
            echo "Quality Gate: ${qualityGates[i]}"
            echo "Revision: ${revisions[i]}"
            echo
        fi
    done
}

function search_project_by_key() {
    check_credential_file $directory
    local search_key="$1"

    set_sonar_url
    return_credential_type
    # JSON data
    get_project_info_from_api
    
    # Print the extracted data
    for ((i=0; i<${#keys[@]}; i++)); do
        if [[ "${keys[i]}" == "$search_key" ]]; then
            # echo "Project $((i+1)): "
            echo "Key: ${keys[i]}"
            echo "Name: ${names[i]}"
            echo "Last Analysis Date: ${dates[i]}"
            echo "Quality Gate: ${qualityGates[i]}"
            echo "Revision: ${revisions[i]}"
            echo
        fi
    done
}

function get_sonarqube_version_from_api() {
    check_credential_file $directory
    set_sonar_url
    return_credential_type

    # JSON data
    case $return_type in
    token)
        response=$(curl -s -o /dev/null -w "%{http_code}" -u "$token:" "$url""/api/server/version")
        ;;
    unpw)
        response=$(curl -s -o /dev/null -w "%{http_code}" -u "$username:$password" "$url""/api/server/version")
        ;;
    esac

    if [ $response -eq 200 ] || [ $response -eq 204 ]; then
        case $return_type in
        token)
            json=$(curl -u "$token:" -s "$url""/api/server/version")
            ;;
        unpw)
            json=$(curl -u "$username:$password" -s "$url""/api/server/version")
            ;;
        esac
    else
        echo "POST request failed with HTTP status code: $response"
    fi
    
    # Extract project information
    echo "$url"" current version is "
    echo "$json"
}

function get_data_from_api() {
    
    return_credential_type
    get_project_info_from_api

    # Extract data using pattern matching
    while [[ $json =~ \"key\":\"([^\"]*)\",\"name\":\"([^\"]*)\",\"lastAnalysisDate\":\"([^\"]*)\",\"qualityGate\":\"([^\"]*)\",\"links\":\[\],\"revision\":\"([^\"]*)\" ]]; do
        keys+=("${BASH_REMATCH[1]}")
        names+=("${BASH_REMATCH[2]}")
        dates+=("${BASH_REMATCH[3]}")
        qualityGates+=("${BASH_REMATCH[4]}")
        revisions+=("${BASH_REMATCH[5]}")
        json=${json#*"\"key\":\"${BASH_REMATCH[1]}\",\"name\":\"${BASH_REMATCH[2]}\",\"lastAnalysisDate\":\"${BASH_REMATCH[3]}\",\"qualityGate\":\"${BASH_REMATCH[4]}\",\"links\":[],\"revision\":\"${BASH_REMATCH[5]}\"}"}
    done
}

function get_project_info_from_api() {
    # JSON data
    case $return_type in
    token)
        response=$(curl -s -o /dev/null -w "%{http_code}" -u "$token:" "$url""/api/projects/search_my_projects")
        ;;
    unpw)
        response=$(curl -s -o /dev/null -w "%{http_code}" -u "$username:$password" "$url""/api/projects/search_my_projects")
        ;;
    esac

    if [ $response -eq 200 ] || [ $response -eq 204 ]; then
        case $return_type in
        token)
            json=$(curl -u "$token:" -s "$url""/api/projects/search_my_projects")
            ;;
        unpw)
            json=$(curl -u "$username:$password" -s "$url""/api/projects/search_my_projects")
            ;;
        esac
    else
        echo "POST request failed with HTTP status code: $response"
    fi

    # Extract project information
    keys=()
    names=()
    dates=()
    qualityGates=()
    revisions=()

    # Extract data using pattern matching
    while [[ $json =~ \"key\":\"([^\"]*)\",\"name\":\"([^\"]*)\",\"lastAnalysisDate\":\"([^\"]*)\",\"qualityGate\":\"([^\"]*)\",\"links\":\[\],\"revision\":\"([^\"]*)\" ]]; do
        keys+=("${BASH_REMATCH[1]}")
        names+=("${BASH_REMATCH[2]}")
        dates+=("${BASH_REMATCH[3]}")
        qualityGates+=("${BASH_REMATCH[4]}")
        revisions+=("${BASH_REMATCH[5]}")
        json=${json#*"\"key\":\"${BASH_REMATCH[1]}\",\"name\":\"${BASH_REMATCH[2]}\",\"lastAnalysisDate\":\"${BASH_REMATCH[3]}\",\"qualityGate\":\"${BASH_REMATCH[4]}\",\"links\":[],\"revision\":\"${BASH_REMATCH[5]}\"}"}
    done

}

#Function to set tag to target project

function set_sonarqube_tag_from_api() {
    check_credential_file $directory
    set_sonar_url
    return_credential_type
    get_data_from_api
    
    # Prompt the user to enter the project key
    read -p "Enter the project key: " PROJECT

    # Prompt the user to enter the comma-separated list of tags
    read -p "Enter list of tags: " TAGS
    
    case $return_type in
    token)
        response=$(curl -s -o /dev/null -w "%{http_code}" -u "$token:" -d "project=$PROJECT&tags=$TAGS" "$url""api/project_tags/set")
        ;;
    unpw)
        response=$(curl -s -o /dev/null -w "%{http_code}" -u "$username:$password" -d "project=$PROJECT&tags=$TAGS" "$url""api/project_tags/set")
        ;;
    esac
    # JSON data
    if [ $response -eq 200 ] || [ $response -eq 204 ]; then
        echo "POST request successful. Please check in following link: "
        echo "$url""dashboard?id=""$PROJECT"
    else
        echo "POST request failed with HTTP status code: $response"

        case $return_type in
        token)
            curl -X POST -u "$token:" -d "project=$PROJECT&tags=$TAGS" "$url""api/project_tags/set"
            ;;
        unpw)
            curl -X POST -u "$username:$password" -d "project=$PROJECT&tags=$TAGS" "$url""api/project_tags/set"
            ;;
        esac
    fi
    
}

function set_sonarqube_tags_from_api() {
    check_credential_file $directory
    set_sonar_url
    return_credential_type
    get_data_from_api

    # Prompt the user to enter the project keys and tags
    read -p "Enter the project keys (comma-separated): " PROJECTS
    read -p "Enter list of tags (comma-separated): " TAGS

    IFS=',' read -r -a PROJECTS_ARRAY <<< "$PROJECTS"
    IFS=',' read -r -a TAGS_ARRAY <<< "$TAGS"

    for ((i=0; i<${#PROJECTS_ARRAY[@]}; i++)); do
        PROJECT="${PROJECTS_ARRAY[i]}"
        TAG="${TAGS_ARRAY[i]}"
        
        case $return_type in
        token)
            response=$(curl -s -o /dev/null -w "%{http_code}" -u "$token:" -d "project=$PROJECT&tags=$TAG" "$url""api/project_tags/set")
            ;;
        unpw)
            response=$(curl -s -o /dev/null -w "%{http_code}" -u "$username:$password" -d "project=$PROJECT&tags=$TAG" "$url""api/project_tags/set")
            ;;
        esac
        
        if [ $response -eq 200 ] || [ $response -eq 204 ]; then
            echo "POST request successful for project: $PROJECT"
            echo "Dashboard link: $url""dashboard?id=$PROJECT"
        else
            echo "POST request failed for project: $PROJECT with HTTP status code: $response"

            case $return_type in
            token)
                curl -X POST -u "$token:" -d "project=$PROJECT&tags=$TAG" "$url""api/project_tags/set"
                ;;
            unpw)
                curl -X POST -u "$username:$password" -d "project=$PROJECT&tags=$TAG" "$url""api/project_tags/set"
                ;;
            esac
        fi
    done
}

# Check if the -d option is provided or help flag (-h)
if [ "$1" = "-d" ]; then
    # Call the function to get project info
    list_project_info
elif [ "$1" = "-sn" ]; then
    # Call the function to search project by name
    if [ $# -eq 2 ]; then
        search_project_by_name "$2"
    else
        echo "Invalid usage. Use: ./script.sh -s \"project_name\", please input project name."
        exit 1
    fi    
elif [ "$1" = "-sk" ]; then
    # Call the function to search project by key
    if [ $# -eq 2 ]; then
        search_project_by_key "$2"
    else
        echo "Invalid usage. Use: ./script.sh -s \"project_key\", please input project key."
        exit 1
    fi       
elif [ "$1" = "-t" ]; then
    echo "Start set tag "
    set_sonarqube_tag_from_api
elif [ "$1" = "-ts" ]; then
    echo "Start set tags "    
    set_sonarqube_tags_from_api
elif [ "$1" = "-c" ]; then
    save_credential_file $directory
elif [ "$1" = "-r" ]; then
    remove_credential_file $directory
elif [ "$1" = "-v" ]; then
    get_sonarqube_version_from_api      
elif [ "$1" = "-h" ] || [ "$1" = "help" ]; then
    echo "Usage: ./script.sh [ -d | -sn | -sk | -t | -ts | -c | -r | -v | -h / help ]"
    echo "-d : Display project information"
    echo "-sn : Search for a project by its name"
    echo "-sk : Search for a project by its key"
    echo "-t : Add tag to specific project"
    echo "-ts : Add muti tags to muti specific project"
    echo "-c : Setup project and credentials"
    echo "-r : Delete credentials"
    echo "-v : Display current version of Sonarqube"
    echo "-h : Show help message"
else
    # Exit if no valid option is provided
    echo "Invalid option. Use -h for help."
    exit 1
fi

