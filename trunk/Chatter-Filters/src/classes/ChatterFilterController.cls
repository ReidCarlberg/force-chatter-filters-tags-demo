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
				if (myFilter == null || myFilter.trim().length() == 0) {
					userFeeds = new ChatterFilterQuery().getPosts();
				} else {
					userFeeds = new ChatterFilterQuery().getPosts(myFilter);
				}
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