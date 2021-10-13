$aplicationName="abertura-de-conta"
$myDeployBucket="$($aplicationName)-alanfachim"

aws s3 rb s3://$myDeployBucket --force   
aws s3api create-bucket --bucket $myDeployBucket --region sa-east-1  --create-bucket-configuration LocationConstraint=sa-east-1 
aws s3 cp .\templates s3://$myDeployBucket/templates --recursive

echo "pronto para iniciar a criação do ambiente"
pause
sam deploy --template-file .\templates\Aplication.yaml  --stack-name $aplicationName --capabilities CAPABILITY_IAM --region sa-east-1 --force-upload --parameter-overrides  LaunchType=Fargate TemplateBucket=$myDeployBucket GitHubBffRepo=$aplicationName GitHubFrontRepo=$aplicationName-front

$CloneUrlFrontEnd = aws cloudformation  describe-stacks --stack-name $aplicationName --query "Stacks[0].Outputs[?OutputKey=='CloneUrlFrontEnd'].OutputValue" --output text 
$CloneUrlBff = aws cloudformation  describe-stacks --stack-name $aplicationName --query "Stacks[0].Outputs[?OutputKey=='CloneUrlBff'].OutputValue" --output text  
$ServiceUrl = aws cloudformation  describe-stacks --stack-name $aplicationName --query "Stacks[0].Outputs[?OutputKey=='CloneUrlBff'].OutputValue" --output text  
$mainUrl=aws cloudformation  describe-stacks --stack-name $aplicationName --query "Stacks[0].Outputs[?OutputKey=='mainUrl'].OutputValue" --output text   
$cognito=aws cloudformation  describe-stacks --stack-name $aplicationName --query "Stacks[0].Outputs[?OutputKey=='cognito'].OutputValue" --output text  

$env=@"
export const environment = { 
 "production": true,
 "title":"$($aplicationName)",
 "tema":"1",
 "loginUrl":"https://fluxodecredito.auth.sa-east-1.amazoncognito.com/login?client_id=$($cognito)&response_type=token&scope=openid&redirect_uri=$($mainUrl)/",
 "api":"/api/v1/"
 }
"@ 
Remove-Item .\FrontEnd\frontend\src\environments\environment.prod.ts
echo $env | Out-File -FilePath .\FrontEnd\frontend\src\environments\environment.prod.ts -encoding ascii

pause 
Remove-Item -Recurse .\FrontEnd\frontend\.git\ -Force
cd .\FrontEnd\frontend\
git init
git remote add origin $CloneUrlFrontEnd
git add .
git commit -m "commit inicial"
git push --set-upstream origin master

pause
cd .\..\..\BFF
Remove-Item -Recurse .git\ -Force
git init
git remote add origin $CloneUrlBff
git add .
git commit -m "commit inicial"
git push --set-upstream origin master
echo "----------------------------------------"
echo $mainUrl
echo "----------------------------------------"
pause
