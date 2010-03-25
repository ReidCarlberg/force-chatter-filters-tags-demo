@isTest class ControllerTests {

	//justs makes sure we get something
	static TestMethod void testKeywordController() {
		
		
		ChatterByKeywordController cont1 = new ChatterByKeywordController();
		cont1.doRefresh();
		cont1.keywordType = null;
		cont1.singleKeyword = null;
		System.assert(cont1.userFeeds != null);
		
		System.assert(cont1.doRefresh() == null);
		System.assert(cont1.doKeywordRefresh() == null);
		System.assert(cont1.simpleKeywords != null);
		
		cont1.singleKeyword = 'test';
		System.assert(cont1.userFeeds != null);
	
	} 
	
	static TestMethod void testFilterController() {
		ChatterFilterController cont2 = new ChatterFilterController();

		System.assert(cont2.userFeeds != null);
		
		System.assert(cont2.myFilters != null);
		 
		System.assert(cont2.doRefresh() == null);
		
	}
	
}