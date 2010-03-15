public with sharing class ChatterByKeywordController {

	public String keywordType { get; set; }
	
	public String singleKeyword { get; set; }
	
	private Boolean isCloud() {
		return keywordType != null && keywordType.toLowerCase() == 'cloud';
	}

	public List<String> simpleKeywords { 
			get {
				if (simpleKeywords == null) {
					if (isCloud()) {
						Set<String> words = new ChatterCloudUtility().buildSignificant();
						simpleKeywords = new List<String>();
						simpleKeywords.addAll(words);
					} else {
						simpleKeywords = new ChatterKeywordQuery().getMyKeywordStrings();
					}
				}
				return simpleKeywords;
			}
			
			private set;
	}
	
	public List<UserFeed> userFeeds {
		get {
			if (userFeeds == null) {
				if (this.singleKeyword != null && this.singleKeyword.trim().length() > 0) {
					userFeeds = new ChatterKeywordQuery().getPosts(this.singleKeyword);
				} else if (isCloud()) {
					userFeeds = new ChatterKeywordQuery().getPosts(simpleKeywords);
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
		return null;
	}
}