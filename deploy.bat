net stop SQLServerReportingServices
copy /Y bin\Debug\Microsoft.Samples.ReportingServices.CustomSecurity.* "c:\Program Files\Microsoft SQL Server Reporting Services\SSRS\Portal\"
copy /Y bin\Debug\Microsoft.Samples.ReportingServices.CustomSecurity.* "c:\Program Files\Microsoft SQL Server Reporting Services\SSRS\ReportServer\bin\"
net start SQLServerReportingServices