#PowerShell
#Script for restore old ad_users (students) to ad 
#Запускать с edu_dom 
#csv_students_source
$csv = Import-Csv "C:\temp\new070524.csv" -Delimiter ';' -Encoding UTF8
#ad_server
$ad_server="edudom"
#root_directory_network_storage
$init_dir = "\\edu.edudom\students$"
#institutes 
$inst_list = "ЭН", "ИнMЭТ", "ММТ", "ТИ", "УMС", "ИНТ", "ИНП"
#ad_units
$ou_users = "CN=Users,DC=edudom"
$ou_deleted = "OU=Удалённые,DC=edudom"
$ou_inpit = "OU=App-EDU,DC=edudom"
#$ou_sei = "OU=OU-Users,OU=SE-EDU,DC=edudom"





function create_new_user {
    param (
        [string]$stud_id,
        [string]$full_name,
        [string]$description,
	    [string]$pass
    )     
    $Password = ConvertTo-SecureString $pass -AsPlainText -Force
    New-ADUser -server $ad_server -Name $stud_id -SamAccountName $stud_id -DisplayName $full_name -AccountPassword $Password -ChangePasswordAtLogon $true -Description $Description -Enabled $true -Path $ou_users

#дополнительный функционал первой очереди
    #create_folder -stud_id $stud_id -home_dir $home_dir
    #set_homedrive_link -stud_id $stud_id -home_dir $home_dir
    #set_acl -stud_id $stud_id -home_dir $home_dir
#дополнительный функционал первой очереди
    #move_user_to_container -stud_id $stud_id
    #adduser_to_inst_group
    #adduser_to_stud_group
             
    Write-Output "user with number: $stud_number and name: $full_name added to ad successfully"
}


function restore_user {
    param (
         
        [string]$stud_id,
        [string]$full_name,
        [string]$description,
	    [string]$pass,
        [string]$home_dir
    )
    $ad_user_desc = Get-ADUser -Server $ad_server -Identity $stud_id -Properties Description | Select-Object Description 

    #check profile on correct discription
    if ($description -ne $ad_user_desc) { 
 #       move_folder -stud_id $stud_id -home_dir $home_dir
 #       move_user_to_container -stud_id $stud_id
 #       clear_groups -stud_id $stud_id
 #       adduser_to_inst_group
 #       adduser_to_stud_group

        set_new_status -stud_id $stud_id -description $description -pass $pass
        #Write-Output "debug 02"
    }   else {
        Write-host "$stud_id 'is ok' skipped ..." -ForegroundColor Red


    }
}


#enable and set new_description
function set_new_status{
     param (
        [string]$stud_id,
        [string]$full_name,
        [string]$description,
	    [string]$pass
    )
    $new_description = $description
    $user_status = Get-ADUser -Identity $stud_id -Properties Enabled | Select-Object -ExpandProperty Enabled
    
    Write-Output $user_status
    if ($false -eq $user_status) { 
        
        $new_pass = ConvertTo-SecureString $pass -AsPlainText -Force              
        Set-ADAccountPassword -Identity $stud_id -NewPassword $new_pass -Reset            
        Set-ADUser -Identity $stud_id -Enabled $true -PasswordNeverExpires $false -ChangePasswordAtLogon $true -Description $new_description
        Write-Output "user: $stud_id Restored, password: Reseted, Description is: $new_decription "
        #Set-ADUser -Identity $stud_id -ChangePasswordAtLogon $true
    } else {
        Set-ADUser -Identity $stud_id -Description $new_description
        Write-Output "Description is: $new_description"
    }
}


function check_user{
    param (
        [string]$stud_id,
        [string]$full_name,
        [string]$description,
	    [string]$pass,
        [string]$home_dir      
    )

    $home_dir="$home_dir$stud_id"


    try {
        $Aduser = Get-ADUser -server $ad_server -Identity $stud_id
        if ($Aduser) {
            #$ad_user_desc = Get-ADUser -Server $ad_server -Identity $stud_id -Properties Description | Select-Object Description
            #call function restore_user
            restore_user -stud_id $stud_id -full_name $full_name -description $description -pass $pass -home_dir $home_dir
        } #else {
            #call function create_user
        #    Write-Output "user $stud_id is New!"
        #    create_new_user -stud_id $stud_id -full_name $full_name -description $description -pass $pass -home_dir $home_dir
        #}
    } catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        Write-Output "user $stud_id is New!"
        create_new_user -stud_id $stud_id -full_name $full_name -description $description -pass $pass -home_dir $home_dir
    } catch {
        Write-Output $_
        #something happened ... 
    }

}

#    try {
#       $Aduser = Get-ADUser -server $ad_server -Identity $stud_id -ErrorAction Stop
#        #call function restore_user      
#        restore_user -stud_id $stud_id -full_name $full_name -description $description -pass $pass -home_dir $home_dir
#    } catch {
#	    #call function create_user
#        Write-Output "user $stud_id is New!"
#        #create_new_user -stud_id $stud_id -full_name $full_name -description $description -pass $pass -home_dir $home_dir
#        
#    }



#foreach all students in csv_list
foreach ($row in $csv) {
    #number
    $students = "$($row.number)"
    #firstname lastname surname
    $full_name = "$($row.full_name)"
    #description
    $description = "$($row.description)"
    #bithday (pass)
    $pass = "$($row.bdate)"
    #prefix 
    $pref = "$($row.edu_form_pref)"
    

    $inst_abbr = $($row.description.Split(' ')[0])
    $group_name = $($row.description.Split(' ')[1]).Substring(0, $($row.description.Split(' ')[1]).Length - 3).Replace("-", "_")
    #$group_name = $($row.description.Split(' ')[1])
    $home_dir = "$init_dir\dev\$pref\$inst_abbr\$group_name\"

    foreach ($stud_number in $students) {
        $inst = $($row.description.Split(' ')[0])

        if ($inst -in $inst_list){
        check_user -stud_id $stud_number -full_name $full_name -description $description -pass $pass -home_dir $home_dir
        }else{
            write-Output "$stud_number skip because 'inst not in list'"    
        }             
        write-Output "======================================================================="
    }
}


