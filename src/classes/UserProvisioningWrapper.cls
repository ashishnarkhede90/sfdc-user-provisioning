public with sharing class UserProvisioningWrapper {
	public UserProvisioningWrapper() {
		
	}

	public List<SelectedPermissionSets> selectedPermissionSets;
	public List<SelectedPackageLicenses> selectedPackageLicenses;
	public UserData userData;
	//public String csvData;

	public class SelectedPackageLicenses {
		public String Id;
		public String Name;
		public String Label;
	}

	public class SelectedPermissionSets {
		public String Id;
		public String Name;
		public String Label;
	}

	public class UserData {
		public String fileName;
		public String data;
		public String format;
	}
	
	public static UserProvisioningWrapper parse(String json) {
		return (UserProvisioningWrapper) System.JSON.deserialize(json, UserProvisioningWrapper.class);
	}
}