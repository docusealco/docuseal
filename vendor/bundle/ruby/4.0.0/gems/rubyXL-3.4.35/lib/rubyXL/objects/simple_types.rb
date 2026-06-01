module RubyXL
  ST_PageOrder           = %w{ downThenOver overThenDown }
  ST_Orientation         = %w{ default portrait landscape }
  ST_CellComments        = %w{ none asDisplayed atEnd }
  ST_PrintError          = %w{ displayed blank dash NA }
  ST_CfvoType            = %w{ num percent max min formula percentile }
  ST_SheetViewType       = %w{ normal pageBreakPreview pageLayout }
  ST_PivotAreaType       = %w{ none normal data all origin button topRight }
  ST_Axis                = %w{ axisRow axisCol axisPage axisValues }
  ST_BorderStyle         = %w{ none thin medium dashed dotted thick double hair
                               mediumDashed dashDot mediumDashDot dashDotDot slantDashDot }
  ST_HorizontalAlignment = %w{ general left center right fill justify centerContinuous distributed }
  ST_VerticalAlignment   = %w{ top center bottom justify distributed }
  ST_VectorBaseType      = %w{ variant i1 i2 i4 i8 ui1 ui2 ui4 ui8 r4 r8
                               lpstr lpwstr bstr date filetime bool cy error clsid cf }
  ST_PhoneticType        = %w{ halfwidthKatakana fullwidthKatakana Hiragana noConversion }
  ST_PhoneticAlignment   = %w{ noControl left center distributed }
  ST_WebSourceType       = %w{ sheet printArea autoFilter range chart pivotTable query label }
  ST_CellType            = %w{ b n e s str inlineStr }
  ST_GradientType        = %w{ linear path }
  ST_PatternType         = %w{ none solid mediumGray darkGray lightGray
                               darkHorizontal darkVertical darkDown darkUp darkGrid darkTrellis
                               lightHorizontal lightVertical lightDown lightUp lightGrid lightTrellis
                               gray125 gray0625 }
  ST_Objects             = %w{ all placeholders none }
  ST_UpdateLinks         = %w{ userSet never always }
  ST_Visibility          = %w{ visible hidden veryHidden }

  ST_DateTimeGrouping    = %w{ year month day hour minute second }
  ST_CalendarType        = %w{ none gregorian gregorianUs japan taiwan korea hijri thai hebrew
                               gregorianMeFrench gregorianArabic gregorianXlitEnglish gregorianXlitFrench }
  ST_FilterOperator      = %w{ equal lessThan lessThanOrEqual notEqual greaterThanOrEqual greaterThan }
  ST_DynamicFilterType   = %w{ null aboveAverage belowAverage tomorrow today yesterday
                               nextWeek thisWeek lastWeek nextMonth thisMonth lastMonth
                               nextQuarter thisQuarter lastQuarter nextYear thisYear lastYear
                               yearToDate Q1 Q2 Q3 Q4 M1 M2 M3 M4 M5 M6 M7 M8 M9 M10 M11 M12 }
  ST_IconSetType         = %w{ 3Arrows 3ArrowsGray 3Flags 3TrafficLights1 3TrafficLights2
                               3Signs 3Symbols 3Symbols2 4Arrows 4ArrowsGray 4RedToBlack
                               4Rating 4TrafficLights 5Arrows 5ArrowsGray 5Rating 5Quarters }
  ST_SortMethod          = %w{ stroke pinYin none }
  ST_SortBy              = %w{ value cellColor fontColor icon }

  ST_CellFormulaType     = %w{ normal array dataTable shared }
  ST_TargetScreenSize    = %w{ 544x376 640x480 720x512 800x600 1024x768 1152x882
                               1152x900 1280x1024 1600x1200 1800x1440 1920x1200 }
  ST_SmartTagShow        = %w{ all none noIndicator }

  ST_CfType              = %w{ expression cellIs colorScale dataBar iconSet top10 uniqueValues
                               duplicateValues containsText notContainsText beginsWith
                               endsWith containsBlanks notContainsBlanks containsErrors
                               notContainsErrors timePeriod aboveAverage }
  ST_TimePeriod          = %w{ today yesterday tomorrow last7Days thisMonth
                                lastMonth nextMonth thisWeek lastWeek nextWeek }
  ST_CalcMode            = %w{ manual auto autoNoTable }
  ST_RefMode             = %w{ A1 R1C1 }

  ST_DvAspect            = %w{ DVASPECT_CONTENT DVASPECT_ICON }
  ST_OleUpdate           = %w{ OLEUPDATE_ALWAYS OLEUPDATE_ONCALL }

  ST_Pane                = %w{ bottomRight topRight bottomLeft topLeft }
  ST_PaneState           = %w{ split frozen frozenSplit }

  ST_Comments            = %w{ commNone commIndicator commIndAndComment }

  ST_DataValidationType       = %w{ none whole decimal list date time textLength custom }
  ST_DataValidationErrorStyle = %w{ stop warning information }
  ST_DataValidationImeMode    = %w{ noControl off on disabled hiragana fullKatakana halfKatakana
                                    fullAlpha halfAlpha fullHangul halfHangul }
  ST_DataValidationOperator   = %w{ between notBetween equal notEqual lessThan lessThanOrEqual
                                    greaterThan greaterThanOrEqual }

  ST_DataConsolidateFunction  = %w{ average count countNums max min
                                    product stdDev stdDevp sum var varp }

  ST_ConditionalFormattingOperator = %w{ lessThan lessThanOrEqual equal notEqual greaterThanOrEqual greaterThan
                                         between notBetween containsText notContains beginsWith endsWith }
  ST_BlackWhiteMode = %w{ clr auto gray ltGray invGray grayWhite blackGray blackWhite black white hidden }
  ST_ShapeType = %w{ line lineInv triangle rtTriangle rect diamond parallelogram trapezoid
                     nonIsoscelesTrapezoid pentagon hexagon heptagon octagon decagon dodecagon
                     star4 star5 star6 star7 star8 star10 star12 star16 star24 star32
                     roundRect round1Rect round2SameRect round2DiagRect snipRoundRect
                     snip1Rect snip2SameRect snip2DiagRect plaque ellipse teardrop homePlate chevron
                     pieWedge pie blockArc donut noSmoking rightArrow leftArrow upArrow downArrow
                     stripedRightArrow notchedRightArrow bentUpArrow
                     leftRightArrow upDownArrow leftUpArrow leftRightUpArrow quadArrow
                     leftArrowCallout rightArrowCallout upArrowCallout downArrowCallout
                     leftRightArrowCallout upDownArrowCallout quadArrowCallout bentArrow uturnArrow circularArrow
                     leftCircularArrow leftRightCircularArrow curvedRightArrow
                     curvedLeftArrow curvedUpArrow curvedDownArrow swooshArrow
                     cube can lightningBolt heart sun moon smileyFace irregularSeal1 irregularSeal2 foldedCorner
                     bevel frame halfFrame corner diagStripe chord arc leftBracket rightBracket leftBrace rightBrace
                     bracketPair bracePair straightConnector1 bentConnector2
                     bentConnector3 bentConnector4 bentConnector5 curvedConnector2 curvedConnector3
                     curvedConnector4 curvedConnector5 callout1 callout2 callout3
                     accentCallout1 accentCallout2 accentCallout3 borderCallout1 borderCallout2 borderCallout3
                     accentBorderCallout1 accentBorderCallout2 accentBorderCallout3
                     wedgeRectCallout wedgeRoundRectCallout wedgeEllipseCallout cloudCallout
                     cloud ribbon ribbon2 ellipseRibbon ellipseRibbon2 leftRightRibbon
                     verticalScroll horizontalScroll wave doubleWave plus
                     flowChartProcess flowChartDecision flowChartInputOutput flowChartPredefinedProcess
                     flowChartInternalStorage flowChartDocument flowChartMultidocument flowChartTerminator
                     flowChartPreparation flowChartManualInput flowChartManualOperation flowChartConnector
                     flowChartPunchedCard flowChartPunchedTape flowChartSummingJunction flowChartOr flowChartCollate
                     flowChartSort flowChartExtract flowChartMerge flowChartOfflineStorage flowChartOnlineStorage
                     flowChartMagneticTape flowChartMagneticDisk flowChartMagneticDrum flowChartDisplay
                     flowChartDelay flowChartAlternateProcess flowChartOffpageConnector actionButtonBlank
                     actionButtonHome actionButtonHelp actionButtonInformation actionButtonForwardNext
                     actionButtonBackPrevious actionButtonEnd actionButtonBeginning actionButtonReturn
                     actionButtonDocument actionButtonSound actionButtonMovie gear6 gear9 funnel
                     mathPlus mathMinus mathMultiply mathDivide mathEqual mathNotEqual
                     cornerTabs squareTabs plaqueTabs chartX chartStar chartPlus }

  ST_SystemColorVal = %w{ scrollBar background activeCaption inactiveCaption menu window windowFrame menuText
                          windowText captionText activeBorder inactiveBorder appWorkspace highlight highlightText
                          btnFace btnShadow grayText btnText inactiveCaptionText btnHighlight 3dDkShadow 3dLight
                          infoText infoBk hotLight gradientActiveCaption gradientInactiveCaption menuHighlight menuBar }

  ST_SchemeColorVal = %w{ bg1 tx1 bg2 tx2 accent1 accent2 accent3 accent4 accent5 accent6
                          hlink folHlink phClr dk1 lt1 dk2 lt2 }

  ST_PresetColorVal = %w{ aliceBlue antiqueWhite aqua aquamarine azure beige bisque black blanchedAlmond blue blueViolet
                          brown burlyWood cadetBlue chartreuse chocolate coral cornflowerBlue cornsilk crimson cyan
                          dkBlue dkCyan dkGoldenrod dkGray dkGreen dkKhaki dkMagenta dkOliveGreen dkOrange
                          dkOrchid dkRed dkSalmon dkSeaGreen dkSlateBlue dkSlateGray dkTurquoise dkViolet
                          deepPink deepSkyBlue dimGray dodgerBlue firebrick floralWhite forestGreen fuchsia
                          gainsboro ghostWhite gold goldenrod gray green greenYellow honeydew hotPink indianRed
                          indigo ivory khaki lavender lavenderBlush lawnGreen lemonChiffon ltBlue ltCoral
                          ltCyan ltGoldenrodYellow ltGray ltGreen ltPink ltSalmon ltSeaGreen ltSkyBlue
                          ltSlateGray ltSteelBlue ltYellow lime limeGreen linen magenta maroon
                          medAquamarine medBlue medOrchid medPurple medSeaGreen medSlateBlue medSpringGreen
                          medTurquoise medVioletRed midnightBlue mintCream mistyRose moccasin navajoWhite
                          navy oldLace olive oliveDrab orange orangeRed orchid paleGoldenrod paleGreen
                          paleTurquoise paleVioletRed papayaWhip peachPuff peru pink plum powderBlue purple
                          red rosyBrown royalBlue saddleBrown salmon sandyBrown seaGreen seaShell sienna
                          silver skyBlue slateBlue slateGray snow springGreen steelBlue tan teal thistle
                          tomato turquoise violet wheat white whiteSmoke yellow yellowGreen }

  ST_PathFillMode         = %w{ none norm lighten lightenLess darken darkenLess }
  ST_TextVertOverflowType = %w{ overflow ellipsis clip }
  ST_TextHorzOverflowType = %w{ overflow clip }
  ST_TextVerticalType     = %w{ horz vert vert270 wordArtVert eaVert mongolianVert wordArtVertRtl }
  ST_TextWrappingType     = %w{ none square }
  ST_TextAnchoringType = %w{ t ctr b just dist }
  ST_TextShapeType        = %w{ textNoShape textPlain textStop textTriangle textTriangleInverted textChevron
                                textChevronInverted textRingInside textRingOutside textArchUp textArchDown
                                textCircle textButton textArchUpPour textArchDownPour textCirclePour textButtonPour
                                textCurveUp textCurveDown textCanUp textCanDown textWave1 textWave2 textDoubleWave1
                                textWave4 textInflate textDeflate textInflateBottom textDeflateBottom textInflateTop
                                textDeflateTop textDeflateInflate textDeflateInflateDeflate textFadeRight
                                textFadeLeft textFadeUp textFadeDown textSlantUp textSlantDown
                                textCascadeUp textCascadeDown }

  ST_PresetMaterialType   = %w{ legacyMatte legacyPlastic legacyMetal legacyWireframe matte plastic metal
                                warmMatte translucentPowder powder dkEdge softEdge clear flat softmetal }

  ST_BevelPresetType      = %w{ relaxedInset circle slope cross angle softRound convex
                                coolSlant divot riblet hardEdge artDeco }


  ST_LineEndType          = %w{ none triangle stealth diamond oval arrow }
  ST_LineEndWidth         = %w{ sm med lg }
  ST_LineEndLength        = %w{ sm med lg }

  ST_PresetLineDashVal    = %w{ solid dot dash lgDash dashDot lgDashDot lgDashDotDot
                                sysDash sysDot sysDashDot sysDashDotDot }

  ST_TileFlipMode         = %w{ none x y xy }
  ST_PathShadeType        = %w{ shape circle rect }

  ST_PresetPatternVal     = %w{ pct5 pct10 pct20 pct25 pct30 pct40 pct50 pct60 pct70 pct75 pct80 pct90
                                horz vert ltHorz ltVert dkHorz dkVert narHorz narVert dashHorz dashVert
                                cross dnDiag upDiag ltDnDiag ltUpDiag dkDnDiag dkUpDiag
                                wdDnDiag wdUpDiag dashDnDiag dashUpDiag diagCross smCheck lgCheck
                                smGrid lgGrid dotGrid smConfetti lgConfetti horzBrick diagBrick
                                solidDmnd openDmnd dotDmnd plaid sphere weave divot shingle wave trellis zigZag }
  ST_RectAlignment        = %w{ tl t tr l ctr r bl b br }
  ST_BlipCompression      = %w{ email screen print hqprint none }
  ST_ColorSchemeIndex     = %w{ dk1 lt1 dk2 lt2 accent1 accent2 accent3 accent4 accent5 accent6 hlink folHlink }
  ST_FontCollectionIndex  = %w{ major minor none }
  ST_BlendMode            = %w{ over mult screen darken lighten }
  ST_PresetCameraType     = %w{ legacyObliqueTopLeft legacyObliqueTop legacyObliqueTopRight legacyObliqueLeft
                                legacyObliqueFront legacyObliqueRight legacyObliqueBottomLeft legacyObliqueBottom
                                legacyObliqueBottomRight legacyPerspectiveTopLeft legacyPerspectiveTop
                                legacyPerspectiveTopRight legacyPerspectiveLeft legacyPerspectiveFront
                                legacyPerspectiveRight legacyPerspectiveBottomLeft legacyPerspectiveBottom
                                legacyPerspectiveBottomRight orthographicFront isometricTopUp isometricTopDown
                                isometricBottomUp isometricBottomDown isometricLeftUp isometricLeftDown
                                isometricRightUp isometricRightDown isometricOffAxis1Left isometricOffAxis1Right
                                isometricOffAxis1Top isometricOffAxis2Left isometricOffAxis2Right isometricOffAxis2Top
                                isometricOffAxis3Left isometricOffAxis3Right isometricOffAxis3Bottom
                                isometricOffAxis4Left isometricOffAxis4Right isometricOffAxis4Bottom
                                obliqueTopLeft obliqueTop obliqueTopRight obliqueLeft obliqueRight obliqueBottomLeft
                                obliqueBottom obliqueBottomRight perspectiveFront perspectiveLeft perspectiveRight
                                perspectiveAbove perspectiveBelow perspectiveAboveLeftFacing perspectiveAboveRightFacing
                                perspectiveContrastingLeftFacing perspectiveContrastingRightFacing
                                perspectiveHeroicLeftFacing perspectiveHeroicRightFacing
                                perspectiveHeroicExtremeLeftFacing perspectiveHeroicExtremeRightFacing
                                perspectiveRelaxed perspectiveRelaxedModerately }
  ST_LightRigType         = %w{ legacyFlat1 legacyFlat2 legacyFlat3 legacyFlat4 legacyNormal1 legacyNormal2
                                legacyNormal3 legacyNormal4 legacyHarsh1 legacyHarsh2 legacyHarsh3 legacyHarsh4
                                threePt balanced soft harsh flood contrasting morning sunrise sunset chilly
                                freezing flat twoPt glow brightRoom }
  ST_LightRigDirection    = %w{ tl t tr l ctr r bl b br }
  ST_EffectContainerType  = %w{ sib tree }
  ST_PresetShadowVal      = %w{ shdw1 shdw2 shdw3 shdw4 shdw5 shdw6 shdw7 shdw8 shdw9 shdw10
                                shdw11 shdw12 shdw13 shdw14 shdw15 shdw16 shdw17 shdw18 shdw19 shdw20 }
  ST_TextTabAlignType     = %w{ l ctr r dec }
  ST_TextAutonumberScheme = %w{ alphaLcParenBoth alphaUcParenBoth alphaLcParenR alphaUcParenR
                                alphaLcPeriod alphaUcPeriod arabicParenBoth arabicParenR arabicPeriod arabicPlain
                                romanLcParenBoth romanUcParenBoth romanLcParenR romanUcParenR
                                romanLcPeriod romanUcPeriod circleNumDbPlain circleNumWdBlackPlain
                                circleNumWdWhitePlain arabicDbPeriod arabicDbPlain ea1ChsPeriod ea1ChsPlain
                                ea1ChtPeriod ea1ChtPlain ea1JpnChsDbPeriod ea1JpnKorPlain ea1JpnKorPeriod
                                arabic1Minus arabic2Minus hebrew2Minus thaiAlphaPeriod thaiAlphaParenR
                                thaiAlphaParenBoth thaiNumPeriod thaiNumParenR thaiNumParenBoth hindiAlphaPeriod
                                hindiNumPeriod hindiNumParenR hindiAlpha1Period }

  ST_TextAlignType        = %w{ l ctr r just justLow dist thaiDist }
  ST_TextFontAlignType    = %w{ auto t ctr base b }
  ST_LineCap              = %w{ rnd sq flat }
  ST_CompoundLine         = %w{ sng dbl thickThin thinThick tri }
  ST_PenAlignment         = %w{ ctr in }

  ST_TextUnderlineType    = %w{ none words sng dbl heavy dotted dottedHeavy dash dashHeavy dashLong dashLongHeavy
                                dotDash dotDashHeavy dotDotDash dotDotDashHeavy wavy wavyHeavy wavyDbl }
  ST_UnderlineValues      = %w{ single double singleAccounting doubleAccounting none }

  ST_TextStrikeType       = %w{ noStrike sngStrike dblStrike }
  ST_TextCapsType         = %w{ none small all }

  # TODO: http://www.datypic.com/sc/ooxml/t-ssml_ST_UnsignedIntHex.html
  ST_UnsignedIntHex       = :string # length = 4
  # TODO: http://www.datypic.com/sc/ooxml/t-ssml_ST_UnsignedShortHex.html
  ST_UnsignedShortHex     = :string # length = 2

  ST_Xstring = :string

  # Query Tables
  ST_GrowShrinkType = %w{ insertDelete insertClear overwriteClear }

  # Connections
  ST_CredMethod             = %w{ integrated none stored prompt }
  ST_ParameterType          = %w{ prompt value cell }
  ST_FileType               = %w{ mac win dos }
  ST_Qualifier              = %w{ doubleQuote singleQuote none }
  ST_ExternalConnectionType = %w{ general text MDY DMY YMD MYD DYM YDM skip EMD }

  ST_HtmlFmt = %w{ none rtf all }
end
