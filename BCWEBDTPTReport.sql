/*
	APPLICATION			:	BCWEB
	DATABASE			:	BCWEB
	REPORT				:	DISCOUNT TRANSPARENCY REPORT
	INPUT PARAMETERS	:	COUNTRY LIST, START DATE AND END DATE.
	EXECUTION HELP		:	SET THE COUNTRY LIST IN THE WHERE CLAUSE OF @CountryIDList.
							SET THE START DATE AND END DATE TO @StartDate AND @EndDate VARIABLES
*/
DECLARE	@CountryIDList TABLE (ISOCountryID INT)
INSERT	INTO @CountryIDList (ISOCountryID)
SELECT	IC.ISOCountryID 
FROM	dbo.ISOCountry IC
--WHERE	IC.ISOCountryDescription IN
--		(
--			'RUSSIA'
--		)


DECLARE @StartDate DATETIME = '2017-01-01'
DECLARE @EndDate DATETIME = '2017-12-31'

-- FINAL OUTPUT QUERY FOR DISCOUNT TRANSPARENCY REPORT
-- THIS QUERY OUTPUT MUST BE COPIED TO AN EXCEL FILE AND SHARED TO THE REQUESTOR
SELECT	
		RegionName = R.RegionDescription,
		Country = IC.ISOCountryDescription,
		RequestNumber = BC.RequestNumber,
		ApprovalNumber = BC.ApprovalNumber,
		CreationDate = CONVERT(VARCHAR(12), BC.CreatedDate, 101),
		RequestDescription = BC.RequestDescription,
		RequestType = RT.RequestTypeDescription,
		SecondaryRequestType = SRT.SecondaryRequestTypeDescription,
		DiscountTransparencyRequired = CASE WHEN BC.IsDTFDeal = 1 THEN 'Required' ELSE 'Not Required' END,
		CustomerName = BCP.BCChannelPartnerCustomerName,
		CustomerEmail = BCP.BCChannelPartnerEmail,
		ChannelPartnerType = CT.CustomerTypeDescription,
		DiscountAmount = 
			(
				SELECT	SUM(ISNULL(PromoDiscountEffectLocalCurrency, 0.0))
				FROM	dbo.PromotionDetail PD WITH (NOLOCK)
						JOIN dbo.Promotion P WITH (NOLOCK) ON P.PromotionID = PD.PromotionID
				WHERE	P.BusinessCaseID = BC.BusinessCaseID
			),
		LocalCurrency = 
			(
				SELECT	MAX(ISNULL(C.CurrencyCode, ''))
				FROM	dbo.PromotionDetail PD WITH (NOLOCK)
						JOIN dbo.Promotion P WITH (NOLOCK) ON P.PromotionID = PD.PromotionID
						JOIN dbo.Currency C WITH (NOLOCK) ON C.CurrencyID = PD.LocalCurrencyID
				WHERE	P.BusinessCaseID = BC.BusinessCaseID
			),
		PartnerName = MO.MailOptionDescription,
		BusinessVertical = BV.BusinessVerticalName,
		RequestDescription = BC.RequestDescription,
		StartDate = CONVERT(VARCHAR(12), BC.BCStartDate, 101),
		EndDate = CONVERT(VARCHAR(12), BC.BCEndDate, 101),
		CreatedBy = (SELECT UserAlias FROM dbo.BCUser WITH (NOLOCK) WHERE BCUserID =  BC.CreatedBy),
		SubmittedBy = (SELECT UserAlias FROM dbo.BCUser WITH (NOLOCK) WHERE BCUserID =  BC.SubmittedBy),
		Justification = REPLACE(REPLACE(BJ.Justification, CHAR(10), ''), CHAR(13), ''),
		BasisForRecommendation = BJ.BasisForRecommendation,
		SpecialDealDetails_SKUCode = PD.SKUCode,
		SpecialDealDetails_SKUDescription = PD.SKUDescription,
		SpecialDealDetails_LocalListPrice = PD.LocalListPrice,
		SpecialDealDetails_DealPrice = PD.PromotionalPrice,
		SpecialDealDetails_Variance = PD.VarienceInPrice,
		SpecialDealDetails_DiscountPercentage = PD.DiscountPercentage
FROM	dbo.BusinessCase BC WITH (NOLOCK)
		JOIN dbo.Region R WITH (NOLOCK) ON R.RegionID = BC.RegionID
		JOIN dbo.BCRequestType RT WITH (NOLOCK) ON RT.RequestTypeID = BC.RequestTypeID
		JOIN dbo.SecondaryRequestType SRT WITH (NOLOCK) ON SRT.SecondaryRequestTypeID = BC.SecondaryRequestTypeID
		JOIN dbo.BCISOCountry BCC WITH (NOLOCK) ON BCC.BusinessCaseID = BC.BusinessCaseID
		JOIN dbo.ISOCountry IC WITH (NOLOCK) ON IC.ISOCountryID = BCC.ISOCountryID
		JOIN @CountryIDList ICLT ON ICLT.ISOCountryID = IC.ISOCountryID
		JOIN dbo.BCChannelPartner BCP WITH (NOLOCK) ON BCP.BusinessCaseID = BC.BusinessCaseID 
			AND BCP.BCChannelPartnerID = (SELECT MAX(BCChannelPartnerID) FROM dbo.BCChannelPartner WITH (NOLOCK) WHERE BusinessCaseID = BCP.BusinessCaseID)
		JOIN dbo.CustomerType CT WITH (NOLOCK) ON CT.CustomerTypeID = BCP.CustomerTypeID
		--JOIN dbo.ChannelPartnerDetails CPD WITH (NOLOCK) ON CPD.ChannelPartnerID = BCP.ChannelPartnerID
		JOIN dbo.BCUser BCU WITH (NOLOCK) ON BCU.BCUserID = BC.CreatedBy
		JOIN dbo.ChannelPartnerDetails CPD WITH (NOLOCK) ON CPD.ChannelPartnerID = BCP.ChannelPartnerID
		JOIN dbo.MailOptions MO WITH (NOLOCK) ON MO.MailOptionID = CPD.MailOptionID
		JOIN dbo.BCBusinessVertical BCBV WITH (NOLOCK) ON BCBV.BusinessCaseID = BC.BusinessCaseID
		JOIN dbo.BusinessVertical BV WITH (NOLOCK) ON BV.BusinessVerticalID = BCBV.BusinessVerticalID
		JOIN dbo.BusinessJustification BJ WITH (NOLOCK) ON BJ.BusinessCaseID = BC.BusinessCaseID
		LEFT JOIN dbo.Promotion P WITH (NOLOCK) ON P.BusinessCaseID = BC.BusinessCaseID
		LEFT JOIN dbo.PromotionDetail PD WITH (NOLOCK) ON PD.PromotionID = P.PromotionID
WHERE	
		CAST(BC.CreatedDate AS DATE) BETWEEN CAST(@StartDate AS DATE) AND CAST(@EndDate AS DATE)
ORDER	BY R.RegionDescription, IC.ISOCountryDescription, BC.CreatedDate, BC.RequestNumber
