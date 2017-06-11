public with sharing class UserProvisioningUtil {
	public String permissionSetJsonObj {get; set;}
	public String packageLicenseJsonObj {get; set;}

	public static String fileName { get; set; }
	public static List<String> filelines { get; set; }
	public static List<UserProvisioningWrapper.SelectedPermissionSets> selectedPermissionSets { get; set; }
	public static List<UserProvisioningWrapper.SelectedPackageLicenses> selectedPackageLicenses { get; set; }
	public static List<UserConfigWrapper> userFlags { get; set; }

	public UserProvisioningUtil() {
		// Get a list of permission sets
		List<PermissionSet> permissionSets = [Select Id, Label, Name from PermissionSet Where ProfileId = null Order By Label];
		permissionSetJsonObj = JSON.serialize(permissionSets);

		List<PackageLicense> packageLicenses = [Select Id, NamespacePrefix from PackageLicense Where NOT NamespacePrefix LIKE 'sf%'];
		List<DnDWrapper> licenseList = new List<DnDWrapper>();

		for (PackageLicense pl: packageLicenses) {
			DnDWrapper dw = new DnDWrapper();
			dw.Id = pl.Id;
			dw.Label = pl.NamespacePrefix;
			dw.Name = pl.NamespacePrefix;

			licenseList.add(dw);
		}

		packageLicenseJsonObj = JSON.serialize(licenseList);
		getUserCheckboxFieldsMap();
	}

	public class DnDWrapper {
		String Id {get; set;}
		String Label {get; set;}
		String Name {get; set;}
	}

	public class UserConfigWrapper {
		public String label { get; set; }
		public String name { get; set; }
		public Boolean isChecked { get; set; }

		public UserConfigWrapper(String label, String name, Boolean isChecked) {
			this.label = label;
			this.name = name;
			this.isChecked = isChecked;
		}
	}

	
	static Map<String, String> permsetMap = new Map<String, String> {'123'=>'Access_to_LMS_Golden_Gate', '456'=>'Docusign_Permissions', '789'=>'DDP_User', '1234'=>'DocuSign_User'}; 
	static Map<String, String> licenseMap = new Map<String, String> {'2344' => 'Steelbrick - SBQQ'};

	public List<SelectOption> getLicenseOptions() {
		List<SelectOption> options = new List<SelectOption>();
		
		for(String key: licenseMap.keyset()) {
			options.add(new SelectOption(key, licenseMap.get(key)));
		}
		return options;
	}

	public List<SelectOption> getPermissionSetOptions() {
		List<SelectOption> options = new List<SelectOption>();
		
		for(String key: permsetMap.keyset()) {
			options.add(new SelectOption(key, permsetMap.get(key)));
		}
		return options;
	}

 	// Method to create csv file for permission set assignment records. Selected permission sets are mapped against each userId in the input file
	public static void createPermissionsetAssignment() {
		
		if(filelines != null && !filelines.isEmpty() && selectedPermissionSets != null && !selectedPermissionSets.isEmpty()) {
			String csvOutput; 

			String header = filelines.get(0).replaceAll('"', '');
			csvOutput = header + ', PermissionSetId' + '\n';

			for(Integer i=1; i<filelines.size(); i++) {
				String fLine = filelines.get(i).replaceAll('"', '');			
				
				for(UserProvisioningWrapper.SelectedPermissionSets ps: selectedPermissionSets) {
			        csvOutput += fLine + ', ' + ps.Id + '\n';
				}
			}

			System.debug(csvOutput);

			ContentVersion file = new ContentVersion(title = fileName + '-PermSetAssignment.csv',versionData = Blob.valueOf( csvOutput ),pathOnClient = '/' + fileName + '-PermSetAssignment.csv');
			insert file;
		}
	}

	public static void createLicenseAssignment() {
		
		if(filelines != null && !filelines.isEmpty() && selectedPackageLicenses != null && !selectedPackageLicenses.isEmpty()) {
			String csvOutput; 

			String header = filelines.get(0).replaceAll('"', '');
			csvOutput = header + ', PackageLicenseId' + '\n';

			for(Integer i=1; i<filelines.size(); i++) {
				String fLine = filelines.get(i).replaceAll('"', '');			
				
				for(UserProvisioningWrapper.SelectedPackageLicenses pl: selectedPackageLicenses) {
			        csvOutput += fLine + ', ' + pl.Id + '\n';
				}
			}

			System.debug(csvOutput);

			ContentVersion file = new ContentVersion(title = fileName + '-LicenseAssignment.csv',versionData = Blob.valueOf( csvOutput ),pathOnClient = '/' + fileName + '-LicenseAssignment.csv');
			insert file;
		}
	}


	public static void getUserCheckboxFieldsMap () {
		Schema.DescribeSobjectResult[] results = Schema.describeSObjects(new String[] {'User'});

		Map<String, SObjectField> fMap = results[0].fields.getMap();

		List<Schema.DescribeFieldResult> dfrList = new List<Schema.DescribeFieldResult>();
		userFlags = new List<UserConfigWrapper>();

		for(SObjectField sof: fMap.values()) {
		    Schema.DescribeFieldResult dfr = sof.getDescribe();
		    dfrList.add(dfr);
		    if(dfr.type == Schema.DisplayType.BOOLEAN && dfr.custom == true && dfr.updateable == true) {
		        userFlags.add(new UserConfigWrapper(dfr.label, dfr.name, false));
		    }
		}
	}

	@RemoteAction
	public static void provisionUsers(String response) {
		
		System.debug(response);

		UserProvisioningWrapper upw = UserProvisioningWrapper.parse(response);
		selectedPermissionSets = upw.selectedPermissionSets;
		selectedPackageLicenses = upw.selectedPackageLicenses;		

		fileName = upw.userData.fileName;
		filelines = new List<String>();
		filelines = upw.userData.data.split('\n');

		system.debug('*** filelines: ' + filelines.size() + ' ' + filelines.get(2));
		System.debug(JSON.serialize(upw));

		createPermissionsetAssignment();
		createLicenseAssignment();
	}
}