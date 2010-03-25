public with sharing class ChatterByKeywordController {

	public String keywordType { 
		get {
			if (keywordType == null) {
				keywordType = 'tag';
			} 
			return keywordType;
		}
		set; 
	}
	
	public String singleKeyword { get; set; }

	public List<String> simpleKeywords { 
			get {
				if (simpleKeywords == null) { 
					simpleKeywords = new List<String>();
					simpleKeywords.addAll( new ChatterCloudUtility().buildKeywords(keywordType) );
					simpleKeywords.sort();
				}
				//simpleKeywords.sort();
				return simpleKeywords;
			}
			
			private set;
	}
	
	public List<UserFeed> userFeeds {
		get {
			if (userFeeds == null) {
				if (this.singleKeyword != null && this.singleKeyword.trim().length() > 0) {
					userFeeds = new ChatterKeywordQuery().getPosts(this.singleKeyword);
				} else if (this.keywordType != null && this.keywordType.length() > 0) {
					Set<String> temp = new Set<String>();
					temp.addAll(simpleKeywords);
					userFeeds = new ChatterKeywordQuery().getPosts(temp);
				} else {
					userFeeds = new ChatterKeywordQuery().getPosts();	
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
	
	public PageReference doKeywordRefresh() {
		simpleKeywords = null;
		userFeeds = null;
		return null;
	}
}