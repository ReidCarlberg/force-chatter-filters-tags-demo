public with sharing class ChatterFilterController {

public String myFilter {get; set;}
	
	public List<Chatter_Filter__c> myFilters {
		get {
			if (myFilters == null) {
				myFilters = new ChatterFilterQuery().getFilters();
			}
			return myFilters;
		}
		private set;
	}
	
	public List<UserFeed> userFeeds {
		get {
			if (userFeeds == null) {
				userFeeds = new ChatterFilterQuery().getFilteredPosts(myFilter); 
			}
			return userFeeds;
		}
		private set;	
	}
	
	public PageReference doRefresh() {
		userFeeds = null;
		return null;
	}
	
}