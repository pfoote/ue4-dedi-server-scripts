$LINUXSERVERPATH="C:\DEV\UE-Game\RELEASES\linux-server\LinuxServer"
$FILENAME="latest-server.zip"
$BUCKETNAME="**********"
$S3ENDPOINTURL="https://s3-ap-southeast-2.amazonaws.com"
$AWSREGION="ap-southeast-2"
$BUCKETPATH="gameserver"
$CANNEDACL="public-read"
$ASGNAME="UE4-GAME"
$SERVERHOSTNAME="***************"
$SCRIPTDIR="C:\DEV\UE-GAME\"

$LOCALZIPFILEPATH="${LINUXSERVERPATH}\${FILENAME}"

cd $LINUXSERVERPATH
rm $LOCALZIPFILEPATH

$7zexe="7z"
&$7zexe a -tzip $LOCALZIPFILEPATH -r -y *

Write-Host "Uploading $FILENAME to $BUCKETNAME"
Write-S3Object -BucketName $BUCKETNAME -File $LOCALZIPFILEPATH -Key "${BUCKETPATH}/${FILENAME}" -CannedACLName $CANNEDACL -EndpointUrl $S3ENDPOINTURL

$ASGOBJ = Get-ASAutoScalingGroup -AutoScalingGroupName $ASGNAME -Region $AWSREGION

if ($ASGOBJ.DesiredCapacity -eq 0) 
{ 
    Write-Host "$ASGNAME - setting desired capacity to 1"
    Update-ASAutoScalingGroup -AutoScalingGroupName $ASGNAME -MaxSize 1 -MinSize 1 -DesiredCapacity 1 -Region $AWSREGION
} 
else 
{
    $ASGOBJ.Instances | % {
        Write-Host "$ASGNAME - Terminating ec2 instance $($_.InstanceId)"
        Remove-EC2Instance -Force -InstanceId $_.InstanceId -Region $AWSREGION
    }
}

cd $SCRIPTDIR

ping -t -w 1000 $SERVERHOSTNAME
