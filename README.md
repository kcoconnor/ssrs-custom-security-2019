# Reporting Services Custom Security Sample
This project contains a sample and the steps that allow you to deploy a custom security extension to SQL Reporting Services 2019.

# Synopsis
# Custom Authentication in SSRS2019

SSRS 2016 introduced a new portal to host new OData APIs and host new report workloads such as mobile reports and KPIS. This new portal relies in newer technologies and is isolated from the familiar ReportingServicesService by running in a separate process. This process is not an ASP.NET hosted application and as such breaks assumptions from existing custom security extensions. Moreover, the current interfaces for custom security extensions don't allow for any external context to be passed-in, leaving implementers with the only choice to inspect well-known global ASP.NET Objects, this required some changes to the interface.

The sample solution was further updated to SSRS2019, using [SSRS 2017 Anonymous Authentication: Problem Solved!](https://www.linkedin.com/pulse/ssrs-2017-anonymous-authentication-problem-solved-frans-van-der-geer/)


## What Changed?

A new interface is introduced that can be implemented which provides an IRSRequestContext providing the more common properties used by extensions to make decisions related to authentication. In previous version ReportManager was the front-end and could be configured with its own custom login page, in SSRS2016 only one page hosted by reportserver is supported and should authenticate to both applications.

In previous versions extensions, could rely on a common assumption that ASP.NET objects would be readily available, since the new portal does not run in asp.net the extension might hit issues with objects being NULL. 
The most generic example is accessing HttpContext.Current to read request information such as headers and cookies. In order to allow extensions to make the same decisions we introduced a new method in the extension that provides request information and is called when authenticating from the portal. 

Extensions should implement the IAuthenticationExtension2 interface to leverage this. The extensions will need to implement both versions of GetUserInfo method, as is called by the reportserver context and other used in webhost process. The sample below shows one of the simple implementations for the portal where the identity resolved by the reportserver is the one used.
  
```csharp
    public void GetUserInfo(IRSRequestContext requestContext, out IIdentity userIdentity, out IntPtr userId)
    {
        userIdentity = null;
        if (requestContext.User != null)
        {

            userIdentity = requestContext.User;
        }
        
        // initialize a pointer to the current user id to zero
        userId = IntPtr.Zero;
   }
```

# Prereqs: 

SQL Server Reporting Services 2019 uses the DotNet Framework 4.6.2.

For the sample, install Visual Studio 2019, as well as the 4.6.2 Developer Pack.

* [Visual Studio 2019](https://aka.ms/vs/16/release/vs_community.exe)
* [Microsoft .NET Framework 4.6.2 Developer Pack](https://support.microsoft.com/en-us/topic/microsoft-net-framework-4-6-2-developer-pack-and-language-packs-5b1b177e-b44e-1e34-7741-1c10c2d62924)

# Implementation 

## Step 1: Building the Sample

You must first compile and install the extension. The procedure assumes that you have installed Reporting Services to the default location: C:\Program Files\Microsoft SQL Server\MSRS13.MSSQLSERVER\Reporting Services. This location will be referred to throughout the remainder of this topic as ```<install>```.

The interface dll is now included in the \lib folder.

If you have not already created a strong name key file, generate the key file using the following instructions.

To generate a strong name key file
-	Open a Microsoft Visual Studio prompt and point to .Net Framework 4.0.
-	Use the change directory command (CD) to change the current directory of the command prompt window to the folder where the project is saved. 
-	At the command prompt, run the following command to generate the key file: sn -k SampleKey.snk .

To compile the sample using MSBuild
-   Run build.bat

To compile the sample using Visual Studio
-	Open CustomSecuritySample.sln in Microsoft Visual Studio. 
-	In Solution Explorer, select the CustomSecuritySample project. 
-	Look at the CustomSecuritySample project's references. If you do not see Microsoft.ReportingServices.Interfaces.dll, then complete the following steps: 
-	On the Project menu, click Add Reference. The Add References dialog box opens. 
-	Click the .NET tab. 
-	Click Browse, and find Microsoft.ReportingServices.Interfaces on your local drive. By default, the assembly is in the ```<install>\ReportServer\bin``` directory. Click OK. The selected reference is added to your project. 
-	On the Build menu, click Build Solution. 

Debugging

To debug the extension, you might want to attach the debugger to both ReportingServicesService.exe and Microsoft.ReportingServices.Portal.Webhost.exe. And add breakpoints to the methods implementing the interface IAuthenticationExtension2.


## Step 2: Deployment and Configuration

The basic configurations needed for custom security extension are the same as previous releases. Following changes are needed in for web.config and rsreportserver.config present in the ReportServer folder. There is no longer a separate web.config for the reportmanager, the portal will inherit the same settings as the reportserver endpoint.

To deploy the sample (cmd.exe Run As Administrator - deploy.bat)
-	Copy the Logon.aspx page to the ```<install>\ReportServer``` directory. 
-	Copy Microsoft.Samples.ReportingServices.CustomSecurity.dll, Microsoft.Samples.ReportingServices.CustomSecurity.dll.config, Microsoft.Samples.ReportingServices.CustomSecurity.pdb to the ```<install>\ReportServer\bin``` directory. 
-	Copy Microsoft.Samples.ReportingServices.CustomSecurity.dll, Microsoft.Samples.ReportingServices.CustomSecurity.dll.config, Microsoft.Samples.ReportingServices.CustomSecurity.pdb to the ```<install>\Portal``` directory. 

If a PDB file is not present, it was not created by the Build step provided above. Ensure that the Project Properties for Debug/Build is set to generate PDB files. 
	
Modify files in the ReportServer Folder
-	To modify the RSReportServer.config file. 
-	Open the RSReportServer.config file with Visual Studio or a simple text editor such as Notepad. RSReportServer.config is located in the ```<install>\ReportServer``` directory. 
-	Locate the ```<AuthenticationTypes>``` element and modify the settings as follows: 
	
	```xml
	<Authentication>
		<AuthenticationTypes> 
			<Custom/>
		</AuthenticationTypes>
		<RSWindowsExtendedProtectionLevel>Off</RSWindowsExtendedProtectionLevel>
		<RSWindowsExtendedProtectionScenario>Proxy</RSWindowsExtendedProtectionScenario>
		<EnableAuthPersistence>true</EnableAuthPersistence>
	</Authentication>
	```

-	Locate the ```<Security>``` and ```<Authentication>``` elements, within the ```<Extensions>``` element, and modify the settings as follows: 

	```xml
	<Security>
		<Extension Name="Forms" Type="Microsoft.Samples.ReportingServices.CustomSecurity.Authorization, Microsoft.Samples.ReportingServices.CustomSecurity" >
		<Configuration>
			<AdminConfiguration>
				<UserName>username</UserName>
			</AdminConfiguration>
		</Configuration>
		</Extension>
	</Security>
	```
	```xml
	<Authentication>
		<Extension Name="Forms" Type="Microsoft.Samples.ReportingServices.CustomSecurity.AuthenticationExtension,Microsoft.Samples.ReportingServices.CustomSecurity" />
	</Authentication> 
	```
To modify the RSSrvPolicy.config file 
-	You will need to add a code group for your custom security extension that grants FullTrust permission for your extension. You do this by adding the code group to the RSSrvPolicy.config file.
-	Open the RSSrvPolicy.config file located in the ```<install>\ReportServer``` directory. 
-	Add the following ```<CodeGroup>``` element after the existing code group in the security policy file that has a URL membership of $CodeGen as indicated below and then add an entry as follows to RSSrvPolicy.config. Make sure to change the below path according to your ReportServer installation directory:
	
	```xml
	<CodeGroup
		class="UnionCodeGroup"
		version="1"
		Name="SecurityExtensionCodeGroup" 
		Description="Code group for the sample security extension"
		PermissionSetName="FullTrust">
	<IMembershipCondition 
		class="UrlMembershipCondition"
		version="1"
		Url="C:\Program Files\Microsoft SQL Server\MSRS13.MSSQLSERVER\Reporting Services\ReportServer\bin\Microsoft.Samples.ReportingServices.CustomSecurity.dll"/>
	</CodeGroup>
	```
Note: 
For simplicity, the Forms Authentication Sample is weak-named and requires a simple URL membership entry in the security policy files. In your production security extension implementation, you should create strong-named assemblies and use the strong name membership condition when adding security policies for your assembly. For more information about strong-named assemblies, see the Creating and Using Strong-Named Assemblies topic on MSDN. 

To modify the Web.config file for Report Server
-	Open the Web.config file in a text editor. By default, the file is in the ```<install>\ReportServer``` directory.
-	Locate the ```<identity>``` element and set the Impersonate attribute to false. 

    ```xml
    <identity impersonate="false" /> 
    ```
-	Locate the ```<authentication>``` element and change the Mode attribute to Forms. Also, add the following ```<forms>``` element as a child of the ```<authentication>``` element and set the loginUrl, name, timeout, and path attributes as follows: 

	```xml
	<authentication mode="Forms">
		<forms loginUrl="logon.aspx" name="sqlAuthCookie" timeout="60" path="/"></forms>
	</authentication> 
	```
-   Add the following ```<authorization>``` element directly after the ```<authentication>``` element. 

	```xml
	<authorization> 
	<deny users="?" />
	</authorization> 
	```

This will deny unauthenticated users the right to access the report server. The previously established loginUrl attribute of the ```<authentication>``` element will redirect unauthenticated requests to the Logon.aspx page.

The logon.aspx page will add the impersonated anonymous user credentials in the page load.


## Step 3: Update the Machine Config

Adding Machine Keys

You should use a validation key specific for you deployment, there are several tools to generate the keys such as Internet Information Services Manager (IIS) or the script detailed in ["Appendix A: How to generate a ```<machineKey>``` element"](https://support.microsoft.com/en-us/help/2915218/resolving-view-state-message-authentication-code-mac-errors#appendixa)

Included you can find a powershell script, Generate-MachineKey.ps1 

Generate an encryption key and copy the output in the machine.config file, which is located in: %windir%\Microsoft.NET\Framework64\v4.0.30319\Config. Put the <machineKey> element just above </system.web> at the bottom of the file.

    <machineKey decryption="AES" decryptionKey="<your key>" validation="SHA1" validationKey="<your validation key>" />

## Step 4: Configure Passthrough cookies

The new portal and the reportserver communicate using internal soap APIs for some of its operations. When additional cookies are required to be passed from the portal to the server the PassThroughCookies properties is still available. More Details: https://msdn.microsoft.com/en-us/library/ms345241.aspx 
In the rsreportserver.config file add following under ```<UI>```

```xml
<UI>
   <CustomAuthenticationUI>
      <PassThroughCookies>
         <PassThroughCookie>sqlAuthCookie</PassThroughCookie>
      </PassThroughCookies>
   </CustomAuthenticationUI>
</UI>
``` 

## Step 5: Restart the Reporting Services Service and the Portal

- Open the services.msc and restart the Reporting Services service
- Open the Reporting Services Config Utility and restart the portal
- Open a Browser and Navigate to the /Reports directory
- Verify the ad/portaluser or whoever you choose as the anonymous user is authenticated


# Code Of Conduct
This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.


