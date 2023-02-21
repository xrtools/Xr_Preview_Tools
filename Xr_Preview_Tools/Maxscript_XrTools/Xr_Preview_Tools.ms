/*****************************************************
***************作者：夏春雨***************************
*************日期：2023.02.07************************
************** QQ：601498315 ***********************
************邮箱：Xr@XrTools.Pro*********************
*****************************************************
*****************************************************/
(
	--前置变量--  
	global v1
	global Xr_Preview_Tools
	global Xr_Preview_About
	global Xr_Preview_Preset_Win
	global Xr_Route = "C:\Maxscript_XrTools\\"
	global Xr_FFmpegFile = Xr_Route + "Conf\ffmpeg.exe" -- ffmpeg路径
	global Xr_Settings_FilePath = Xr_Route + "Conf\\Xr_Settings.ini"
	global Xr_UploadFileRoute = "XrTools_UploadFile_Data\\"
	global Xr_Preview_PreviewName
	global Xr_Preview_PreviewPath
	global Xr_Preview_GetPreviewPath
	global Xr_Preview_GetPreviewName
	global Xr_Preview_SetFormat = "Avi"
	global Xr_Preview_BatchValue = 0
	global Xr_Preview_SaveViewInt = 0
	global Xr_Preview_AppStartingValue = 0
	-- 渲染尺寸变量
	global Xr_Preview_RenderWidthValue
	global Xr_Preview_RenderHeightValue
	-- 预设 首选项
	global Xr_Preview_ScreenPresets = #("高质量","标准","性能","DX 性能")
	global Xr_Preview_ScreenPreferences = #("默认明暗处理","面","边界框","平面颜色","隐藏线","粘土")
	global Xr_Preview_ScreenPresetsValue
	global Xr_Preview_ScreenPreferencesValue

	if maxfilepath != "" then
	(
		Xr_Preview_PreviewName = getFilenameFile maxFileName
		Xr_Preview_PreviewPath = maxfilepath
	)else(
		Xr_Preview_PreviewName = "UnTitled"
		Xr_Preview_PreviewPath = "UnTitled"
	)

	try(DestroyDialog Xr_Preview_Tools)catch()
	try(DestroyDialog Xr_Preview_About)catch()
	try(DestroyDialog Xr_Preview_Preset_Win)catch()
	-----------Ini 增删改查
	struct Xr_StINISetting
	(
		fn Xr_SetINISetting Xr_GetINI_Section Xr_GetINI_Key Xr_GetINI_NewKey =
		(
			setINISetting Xr_Settings_FilePath Xr_GetINI_Section Xr_GetINI_Key Xr_GetINI_NewKey
		),

		fn Xr_GetINISetting Xr_GetINI_Section Xr_GetINI_Key = 
		(
			getINISetting Xr_Settings_FilePath Xr_GetINI_Section Xr_GetINI_Key
		)
	)

	struct Xr_Preview_Language
	(
		defaultLang = "Xr_Preview_Chinese",
		ext = @".lng",
		pth = Xr_Route + @"Conf\",
		defaultFile = pth + defaultLang + ext,

		fn getLang =
		(		
			local l = Xr_StINISetting.Xr_GetINISetting "Xr_PreviewConf" "Language"
			local f = pth + l + ext
			if(l == "") do return defaultFile
			return f
		),

		lang = getLang(),

		fn getTranslate l sec: "UI" =
		(
			local f = getLang()
			local o = getIniSetting f sec l
			if(o == "") do return l
			
			o = substituteString o " || " "\n\n"
			o = substituteString o " | " "\n"
			return o
		),

		fn translateUi r =
		(
			for i in 1 to r.controls.count do
			(
				local c = r.controls[i]
				local isCaptionExist = c.caption[1] == "~"
				local isTextExist = try(c.text[1] == "~") catch(false)
				local isTagExist = try(c.tag[1] == "~") catch(false)
				
				if(isCaptionExist) do
				(
					c.caption = getTranslate (c.caption)
				)
				if(isTextExist ) do
				(
					c.text = getTranslate (c.text)
				)
				if(isTagExist) do
				(
					c.text = getTranslate (c.tag)
				)
			)
		)
	)

	global Xr_Preview_Lng = Xr_Preview_Language()

	------ 弹窗
	fn Xr_Popup PopupText = (messageBox (Xr_Preview_Lng.getTranslate PopupText) title:"Xr Preview Tools" beep:false)
	fn Xr_PopupQuery PopupText = (return querybox PopupText title:"Xr Preview Tools" beep:false)
	fn MakeThumbnail =
	(
		grab_bmp = gw.getViewportDib()
		croppedScreenGrab = bitmap grab_bmp.height grab_bmp.height 
		pasteBitmap grab_bmp croppedScreenGrab [((grab_bmp.width - grab_bmp.height)/2)+1,1] [0,0]  -- paste the orginal image to the tempImage, this results in a cropped image widh same height as width
		outputMap  = bitmap 119 119
		copy croppedScreenGrab outputMap 
		close grab_bmp
		close croppedScreenGrab
		
		gc light:true
		outputMap
	)
	
	fn Xr_Preview_FN =
	(
		--设置渲染尺寸
		renderWidth = Xr_Preview_RenderWidthValue as Integer
		renderHeight = Xr_Preview_RenderHeightValue as Integer

		renderSceneDialog.Update()
		
		Xr_PreviewStart = (animationRange.start.frame as integer)
		Xr_PreviewEnd = (animationRange.end.frame as integer)
		
		maxVersionS = maxVersion()
		if maxVersionS[1] >= 22000 then
		(
			videoin = getDir #preview + "\\" + getFilenameFile maxFileName + "_preview.avi"
		)else(
			videoin = getDir #preview + "\_scene.avi"
		)

		videoout = Xr_Preview_GetPreviewPath + "Avi\\" + Xr_Preview_GetPreviewName
		if doesFileExist (Xr_Preview_GetPreviewPath + "Avi\\") == false then
		(
			makeDir (Xr_Preview_GetPreviewPath + "Avi\\") 
		)

		-- 导出前先清理旧文件
		if doesFileExist videoin == true then 
		(
			CreatefilePatha = createfile videoin
			close CreatefilePatha
			deletefile videoin
		)

		FileExtension = #(".avi",".mp4",".gif")
		for F = 1 to FileExtension.count do
		(
			if doesFileExist (videoout + FileExtension[F]) == true then 
			(
				CreatefilePathb = createfile (videoout + FileExtension[F])
				close CreatefilePathb
				deletefile (videoout + FileExtension[F])
			)
		)

		--                 ↓显示帧数↓      ↓隐藏活动栅格↓   ↓隐藏摄像机↓ 	  ↓显示模型↓	↓隐藏图形↓		 ↓隐藏灯光↓		↓隐藏辅助对象↓		↓隐藏粒子↓		↓隐藏骨骼↓		↓不显示安全框↓	 ↓不显示背景↓ ↓输出百分比为100↓ ↓起始和结束帧直接获取下当前的↓
		createPreview dspFrameNums:true dspGrid:false dspCameras:false dspGeometr:true dspShapes:false dspLights:false dspHelpers:false dspParticles:false dspBones:false dspSafeFrame:false dspBkg:false percentSize:100 start:Xr_PreviewStart end:Xr_PreviewEnd

		if Xr_Preview_SetFormat == "Avi" then
		(
			FFmpeg_SetFormat = " -vcodec h264 -pix_fmt yuv420p " + "\"" + (videoout + ".avi")
		)else if Xr_Preview_SetFormat == "Mp4" then
		(
			FFmpeg_SetFormat = " -c:v libx264 -pix_fmt yuv420p " + "\"" + (videoout + ".mp4")
		)else if Xr_Preview_SetFormat == "Gif" then
		(
			FFmpeg_SetFormat = " -filter_complex \"[0]split[a][b]; [a]palettegen[palette]; [b][palette]paletteuse\" " + "\"" + (videoout + ".gif")
		)else(FFmpeg_SetFormat = "\"" + (videoout + ".mp4"))

		convertout = Xr_FFmpegFile + " -i \"" + videoin + "\"" + FFmpeg_SetFormat + "\"" + " -y -loglevel quiet"
		HiddenDOSCommand convertout donotwait:true exitCode:&exitcode
	)

	struct vpSave (
		tmMatrix,
		screenGrab,
		vpType,
		
		fn saveTM =(
			try(
				vpType = viewport.getType()
				tmMatrix = getViewTM()

				Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "vpType" vpType
				Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "tmMatrix_1_1" (tmMatrix[1][1] as string)
				Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "tmMatrix_1_2" (tmMatrix[1][2] as string)
				Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "tmMatrix_1_3" (tmMatrix[1][3] as string)
				
				Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "tmMatrix_2_1" (tmMatrix[2][1] as string)
				Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "tmMatrix_2_2" (tmMatrix[2][2] as string)
				Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "tmMatrix_2_3" (tmMatrix[2][3] as string)
				
				Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "tmMatrix_3_1" (tmMatrix[3][1] as string)
				Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "tmMatrix_3_2" (tmMatrix[3][2] as string)
				Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "tmMatrix_3_3" (tmMatrix[3][3] as string)
				
				Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "tmMatrix_4_1" (tmMatrix[4][1] as string)
				Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "tmMatrix_4_2" (tmMatrix[4][2] as string)
				Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "tmMatrix_4_3" (tmMatrix[4][3] as string)
			)catch()
		),
		fn getTM =(
			try(
				viewport.setType vpType
				viewport.setTM tmMatrix
			)catch()
		),
		fn setScreenGrab =(
			screenGrab = (MakeThumbnail())
		)
	)
----------------------- About
	rollout Xr_Preview_About "About" width:300 height:180
	(
		dotNetControl Xr_About_biaoti "System.Windows.Forms.Label" pos:[0,0] width:312 height:30
		dotNetControl Xr_About_fubiaoti "System.Windows.Forms.Label" pos:[0,31] width:312 height:18
		GroupBox Xr_About_Grb "" pos:[5,52] width:290 height:120
		label Xr_About_Lab_1 "-- TG.Xr --" pos:[120,75] width:80 height:15
		label Xr_About_Lab_2 "Email: Xr@XrTools.Pro" pos:[88,114] width:200 height:15
		label Xr_About_Lab_3 "v 1.2" pos:[136,93] width:80 height:15
		HyperLink Xr_About_Web "Xr Preview 使用文档" pos:[92,140] width:135 height:15 color:(color 255 0 0) hovercolor:(color 0 255 255) address:"https://xrtools.pro/index.php/109.html"
		
		on Xr_Preview_About open do
		(
			bold = (dotnetclass "System.Drawing.FontStyle").Bold
			Xr_About_biaoti.text = "--   Xr Preview Tools   --"
			Xr_About_biaoti.font= dotnetobject "System.Drawing.Font" "微软雅黑" 16 bold
			Xr_About_biaoti.backcolor = Xr_About_biaoti.backcolor.fromARGB 136 214 210
			Xr_About_biaoti.TextAlign = (dotNetClass "System.Drawing.ContentAlignment").MiddleCenter
			Xr_About_fubiaoti.text = "--- 关于 ---"
			Xr_About_fubiaoti.font= dotnetobject "System.Drawing.Font" "微软雅黑" 9 bold
			Xr_About_fubiaoti.backcolor = Xr_About_fubiaoti.backcolor.fromARGB 105 105 105
			Xr_About_fubiaoti.TextAlign = (dotNetClass "System.Drawing.ContentAlignment").MiddleCenter
		)
	)
---------------------输入预设名称窗口
	rollout Xr_Preview_Preset_Win "Xr Preview Preset" width:350 height:220
	(
		dotNetControl Xr_PreviewPreset_Title_1 "System.Windows.Forms.Label" pos:[15,7] width:320 height:18
		GroupBox Xr_PreviewPreset_GrpBox_1 "" width:330 height:73 pos:[10,25]

		button Xr_PreviewPreset_RenderW1920H1080 "1920x1080" pos:[15,39] width:95 height:20
		button Xr_PreviewPreset_RenderW1280H720 "1280x720" pos:[120,39] width:95 height:20
		button Xr_PreviewPreset_RenderW480H270 "480x270" pos:[15,69] width:95 height:20
		button Xr_PreviewPreset_RenderW320H180 "320x180" pos:[120,69] width:95 height:20

		label Xr_PreviewPreset_Title_2 "渲染宽度:" pos:[230,42] width:55 height:20
		spinner Xr_PreviewPreset_RenderWidthValue ""  pos:[286,41] width:45 height:20 range:[1,9999,1280] type:#integer
		label Xr_PreviewPreset_Title_3 "渲染高度:" pos:[230,72] width:55 height:20
		spinner Xr_PreviewPreset_RenderHeightValue ""  pos:[286,71] width:45 height:20 range:[1,9999,720] type:#integer

		dotNetControl Xr_PreviewPreset_Title_4 "System.Windows.Forms.Label" pos:[15,105] width:320 height:18
		GroupBox Xr_PreviewPreset_GrpBox_2 "" width:330 height:45 pos:[10,123]

		label Xr_PreviewPreset_Title_5 "画面预设:" align:#center pos:[20,142]
		dropdownlist Xr_PreviewPreset_ScreenPresetsList items:Xr_Preview_ScreenPresets across: 3 pos:[75,138] width:75 enabled:true visible:true
		label Xr_PreviewPreset_Title_6 "画面首选项:" align:#center pos:[160,142]
		dropdownlist Xr_PreviewPreset_ScreenPreferencesList items:Xr_Preview_ScreenPreferences across: 3 pos:[230,138] width:105 enabled:true visible:true

		button Xr_PreviewPreset_OK "完成" pos:[8,175] width:162 height:35
		button Xr_PreviewPreset_Cancel "取消" pos:[180,175] width:162 height:35

		on Xr_Preview_Preset_Win open do
		(
			bold = (dotnetclass "System.Drawing.FontStyle").Bold
			ComboBoxStyle = dotNetClass "System.Windows.Forms.ComboBoxStyle"

			Xr_PreviewPreset_Title_1.text = "分辨率设置"
			Xr_PreviewPreset_Title_1.backcolor = Xr_PreviewPreset_Title_1.backcolor.fromARGB 105 105 105
			Xr_PreviewPreset_Title_1.font= dotnetobject "System.Drawing.Font" "微软雅黑" 9 bold
			Xr_PreviewPreset_Title_1.TextAlign = (dotNetClass "System.Drawing.ContentAlignment").MiddleCenter

			Xr_PreviewPreset_Title_4.text = "后台拍屏显示设置"
			Xr_PreviewPreset_Title_4.backcolor = Xr_PreviewPreset_Title_4.backcolor.fromARGB 105 105 105
			Xr_PreviewPreset_Title_4.font= dotnetobject "System.Drawing.Font" "微软雅黑" 9 bold
			Xr_PreviewPreset_Title_4.TextAlign = (dotNetClass "System.Drawing.ContentAlignment").MiddleCenter

			Xr_Preview_RenderWidthValue = Xr_StINISetting.Xr_GetINISetting "Xr_PreviewConf" "RenderWidthValue"
			Xr_Preview_RenderHeightValue = Xr_StINISetting.Xr_GetINISetting "Xr_PreviewConf" "RenderHeightValue"
			Xr_Preview_ScreenPresetsValue = Xr_StINISetting.Xr_GetINISetting "Xr_PreviewConf" "ScreenPresetsList"
			Xr_Preview_ScreenPreferencesValue = Xr_StINISetting.Xr_GetINISetting "Xr_PreviewConf" "ScreenPreferencesList"

			Xr_PreviewPreset_RenderWidthValue.value = Xr_Preview_RenderWidthValue as Integer
			Xr_PreviewPreset_RenderHeightValue.value = Xr_Preview_RenderHeightValue as Integer
			Xr_PreviewPreset_ScreenPresetsList.selection = Xr_Preview_ScreenPresetsValue as Integer
			Xr_PreviewPreset_ScreenPreferencesList.selection = Xr_Preview_ScreenPreferencesValue as Integer
		)
		--->>>>>>>>>>>>>>>>>>>>>>>>>>   更改分辨率
		on Xr_PreviewPreset_RenderW1920H1080 pressed do
		(
			Xr_PreviewPreset_RenderWidthValue.value = Xr_Preview_RenderWidthValue = 1920
			Xr_PreviewPreset_RenderHeightValue.value = Xr_Preview_RenderHeightValue = 1080
		)
		on Xr_PreviewPreset_RenderW1280H720 pressed do
		(
			Xr_PreviewPreset_RenderWidthValue.value = Xr_Preview_RenderWidthValue = 1280
			Xr_PreviewPreset_RenderHeightValue.value = Xr_Preview_RenderHeightValue = 720
		)
		on Xr_PreviewPreset_RenderW480H270 pressed do
		(
			Xr_PreviewPreset_RenderWidthValue.value = Xr_Preview_RenderWidthValue = 480
			Xr_PreviewPreset_RenderHeightValue.value = Xr_Preview_RenderHeightValue = 270
		)
		on Xr_PreviewPreset_RenderW320H180 pressed do
		(
			Xr_PreviewPreset_RenderWidthValue.value = Xr_Preview_RenderWidthValue = 320
			Xr_PreviewPreset_RenderHeightValue.value = Xr_Preview_RenderHeightValue = 180
		)
		--->>>>>>>>>>>>>>>>>>>>>>>>>>   自定义更改分辨率
		on Xr_PreviewPreset_RenderWidthValue changed val do (Xr_Preview_RenderWidthValue = Xr_PreviewPreset_RenderWidthValue.value)
		on Xr_PreviewPreset_RenderHeightValue changed val do (Xr_Preview_RenderHeightValue = Xr_PreviewPreset_RenderHeightValue.value)

		on Xr_PreviewPreset_OK pressed do
		(
			
			-- 1.高质量 2.标准 3.性能 4.DX 性能
			-- 1.默认明暗处理 2.面 3.边界框 4.平面颜色 5.隐藏线 6.粘土
			Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "ScreenPresetsList" (Xr_PreviewPreset_ScreenPresetsList.selection as string)
			Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "ScreenPreferencesList" (Xr_PreviewPreset_ScreenPreferencesList.selection as string)
			Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "RenderWidthValue" (Xr_Preview_RenderWidthValue as string)
			Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "RenderHeightValue" (Xr_Preview_RenderHeightValue as string)
			Xr_Popup "设置完成！"
			destroyDialog Xr_Preview_Preset_Win
		)
		on Xr_PreviewPreset_Cancel pressed do (destroyDialog Xr_Preview_Preset_Win)
	)
---------------------主界面
	rollout Xr_Preview_Tools "Xr Preview Tools" width:400 height:285
	(
		dotNetControl Xr_Preview_Label_1 "System.Windows.Forms.Label" pos:[0,0] width:400 height:33
		dotNetControl Xr_Preview_Label_2 "System.Windows.Forms.Label" pos:[0,33] width:400 height:20
		
		button Xr_Preview_View "- - - - - - -" across:2 pos:[8,67] width:120 height:120
		button Xr_Preview_GetView "~Xr_PreviewUI_GetView~" pos:[8,194] width:120 height:28
		
		GroupBox Xr_Preview_GrpBox_1 "" pos:[133,62] width:262 height:124

		label Xr_Preview_Label_PreviewName "~Xr_PreviewUI_Label_PreviewName~" pos:[145,82] width:55 height:20 align:#center
		editText Xr_Preview_FileName "" pos:[205,79] enabled:false width:155 height:18
		button Xr_Preview_UpDate "~Xr_PreviewUI_UpDate~" pos:[364,78] width:20 height:20 images:#(Xr_Route + "img\\Xr_ExportFile_Tools\\UVWUnwrapModes_16i.bmp", Xr_Route + "img\\Xr_ExportFile_Tools\\UVWUnwrapModes_16a.bmp",28,3,3,3,3,true)
		
		label Xr_Preview_Label_PreviewPath "~Xr_PreviewUI_Label_PreviewPath~" pos:[145,110] width:55 height:20 align:#center
		editText Xr_Preview_FilePath "" pos:[205,107] enabled:false width:155 height:18
		button Xr_Preview_Browse "~Xr_PreviewUI_Browse~" enabled:false pos:[364,106] width:20 height:20 images:#(Xr_Route + "img\\Xr_ExportFile_Tools\\bip_general_i.bmp",Xr_Route + "img\\Xr_ExportFile_Tools\\bip_general_i.bmp",30,5,6,6,6,true)
		
		checkbox Xr_Preview_UseFileName "~Xr_PreviewUI_UseFileName~" pos:[155,136] width:100 height:20 checked:true enabled:true
		checkbox Xr_Preview_UseFilePath "~Xr_PreviewUI_UseFilePath~" pos:[261,136] width:100 height:20 checked:true enabled:true
		checkbox Xr_Preview_BatchPreview "~Xr_PreviewUI_BatchPreview~" pos:[155,161] width:100 height:20 checked:false enabled:true
		checkbox Xr_Preview_AppStarting "~Xr_PreviewUI_AppStarting~" pos:[261,161] width:100 height:20 checked:false enabled:true
		
		GroupBox Xr_Preview_GrpBox_2 "" pos:[133,187] width:262 height:35
		button Xr_Preview_Format "" pos:[142,199] width:35 height:18
		button Xr_Preview_Setting "~Xr_PreviewUI_Setting~" pos:[197,199] width:35 height:18
		button Xr_Preview_Language pos:[252,199] width:35 height:18
		button Xr_Preview_Help "~Xr_PreviewUI_Help~" pos:[307,199] width:35 height:18
		button Xr_Preview_SetUpList "设置" pos:[364,199] width:20 height:18  images:#(Xr_Route + "img\\Xr_ExportFile_Tools\\PhysX_Main_24i.bmp", Xr_Route + "img\\Xr_ExportFile_Tools\\PhysX_Main_24a.bmp",33,28,28,28,28,true) tooltip:"拍屏设置"
		
		button Xr_Preview_Run "~Xr_PreviewUI_Run~" pos:[8,232] width:386 height:45
	
		on Xr_Preview_Tools open do
		(
			Xr_Preview_Lng.translateUi Xr_Preview_Tools
			v1 = vpSave()
			try(Xr_Preview_GetView.pressed())catch()
			bold = (dotnetclass "System.Drawing.FontStyle").Bold

			Xr_Preview_Label_1.text = "Xr Preview Tools"
			Xr_Preview_Label_1.font= dotnetobject "System.Drawing.Font" "微软雅黑" 16 bold
			Xr_Preview_Label_1.backcolor = Xr_Preview_Label_1.backcolor.fromARGB 136 214 210
			Xr_Preview_Label_1.foreColor = Xr_Preview_Label_1.backcolor.fromARGB 0 0 0
			Xr_Preview_Label_1.TextAlign = (dotNetClass "System.Drawing.ContentAlignment").MiddleCenter

			Xr_Preview_Label_2.text = "--- TG Xr ---"
			Xr_Preview_Label_2.backcolor = Xr_Preview_Label_2.backcolor.fromARGB  180 180 180 
			Xr_Preview_Label_2.foreColor = Xr_Preview_Label_2.backcolor.fromARGB 90 90 90
			Xr_Preview_Label_2.font= dotnetobject "System.Drawing.Font" "微软雅黑" 9
			Xr_Preview_Label_2.font= dotnetobject "System.Drawing.Font" "微软雅黑" 9 bold
			Xr_Preview_Label_2.TextAlign = (dotNetClass "System.Drawing.ContentAlignment").MiddleCenter

			if doesFileExist Xr_Route == false then (makeDir Xr_Route)
			if doesFileExist (Xr_Route + "\\Conf\\") == false then (makeDir (Xr_Route + "\\Conf\\"))
			if doesFileExist (Xr_Route + "\\XrTools_Data\\") == false then (makeDir (Xr_Route + "\\XrTools_Data\\"))

			Xr_Preview_FileName.text = Xr_Preview_PreviewName
			Xr_Preview_FilePath.text = Xr_Preview_PreviewPath
			
			-- 判断当前 是否存在配置文件
			if doesFileExist Xr_Settings_FilePath == true then
			(
				Xr_Preview_LanguageText = Xr_StINISetting.Xr_GetINISetting "Xr_PreviewConf" "Lang"
				if Xr_Preview_LanguageText != "" then
				(
					Xr_Preview_Language.text = Xr_Preview_LanguageText
				)else(
					Xr_Preview_Language.text = "Zh"
					Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "Language" "Xr_Preview_Chinese"
				)

				Xr_Preview_FormatText = Xr_StINISetting.Xr_GetINISetting "Xr_PreviewConf" "Format"
				if Xr_Preview_FormatText != "" then
				(
					Xr_Preview_Format.text = Xr_Preview_FormatText
					Xr_Preview_SetFormat = Xr_Preview_FormatText
				)else(
					Xr_Preview_Format.text = "Avi"
					Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "Format" "Avi"
				)

				Xr_Preview_RenderWidthValue = Xr_StINISetting.Xr_GetINISetting "Xr_PreviewConf" "RenderWidthValue"
				if Xr_Preview_RenderWidthValue == "" then
				(
					Xr_Preview_RenderWidthValue = 1280
					Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "RenderWidthValue" "1280"
				)
				Xr_Preview_RenderHeightValue = Xr_StINISetting.Xr_GetINISetting "Xr_PreviewConf" "RenderHeightValue"
				if Xr_Preview_RenderHeightValue == "" then
				(
					Xr_Preview_RenderHeightValue = 720
					Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "RenderHeightValue" "720"
				)

				Xr_Preview_ScreenPresetsValue = Xr_StINISetting.Xr_GetINISetting "Xr_PreviewConf" "ScreenPresetsList"
				if Xr_Preview_ScreenPresetsValue == "" then
				(
					Xr_Preview_ScreenPresetsValue = 3
					Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "ScreenPresetsList" "3"
				)
				Xr_Preview_ScreenPreferencesValue = Xr_StINISetting.Xr_GetINISetting "Xr_PreviewConf" "ScreenPreferencesList"
				if Xr_Preview_ScreenPreferencesValue == "" then
				(
					Xr_Preview_ScreenPreferencesValue = 1
					Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "ScreenPreferencesList" "1"
				)

			)else(
				Xr_Preview_Language.text = "Zh"
				Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "Language" "Xr_Preview_Chinese"

				Xr_Preview_Format.text = "Avi"
				Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "Format" "Avi"

				Xr_Preview_RenderWidthValue = 1280
				Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "RenderWidthValue" "1280"
				Xr_Preview_RenderHeightValue = 720
				Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "RenderHeightValue" "720"

				Xr_Preview_ScreenPresetsValue = 3
				Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "ScreenPresetsList" "3"
				Xr_Preview_ScreenPreferencesValue = 1
				Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "ScreenPreferencesList" "1"
			)

			Xr_Preview_GetView.tooltip = Xr_Preview_Lng.getTranslate "~Xr_PreviewUI_GetView_tooltip~"
			Xr_Preview_UpDate.tooltip = Xr_Preview_Lng.getTranslate "~Xr_PreviewUI_UpDate_tooltip~"
			Xr_Preview_Browse.tooltip = Xr_Preview_Lng.getTranslate "~Xr_PreviewUI_Browse_tooltip~"
			Xr_Preview_UseFileName.tooltip = Xr_Preview_Lng.getTranslate "~Xr_PreviewUI_UseFileName_tooltip~"
			Xr_Preview_UseFilePath.tooltip = Xr_Preview_Lng.getTranslate "~Xr_PreviewUI_UseFilePath_tooltip~"
			Xr_Preview_BatchPreview.tooltip = Xr_Preview_Lng.getTranslate "~Xr_PreviewUI_BatchPreview_tooltip~"
			Xr_Preview_AppStarting.tooltip = Xr_Preview_Lng.getTranslate "~Xr_PreviewUI_AppStarting_tooltip~"
			Xr_Preview_Setting.tooltip = Xr_Preview_Lng.getTranslate "~Xr_PreviewUI_Setting_tooltip~"
			Xr_Preview_Language.tooltip = Xr_Preview_Lng.getTranslate "~Xr_PreviewUI_Language_tooltip~"
			Xr_Preview_Run.tooltip = Xr_Preview_Lng.getTranslate "~Xr_PreviewUI_Run_tooltip~"

			if doesFileExist Xr_FFmpegFile == false then (Xr_Popup "~Xr_PreviewUI_FFmpeg_messageBox~")
		)
		
		on Xr_Preview_View pressed do v1.getTM()

		on Xr_Preview_GetView pressed do
		(
			try(
				v1.saveTM()
				v1.setScreenGrab()
				Xr_Preview_View.images = #(v1.screengrab, undefined, 1,1,1,1,1)
				Xr_Preview_SaveViewInt = 1
			)catch(Xr_Popup "获取视图失败！")
		)
		
		on Xr_Preview_UseFileName changed Xr_Preview_UseFileName_state do
		(
			if Xr_Preview_UseFileName_state == false then
			(
				Xr_Preview_FileName.enabled = true -- Enable Custom Preview Name
				Xr_Preview_FileName.text = Xr_Preview_Lng.getTranslate "~Xr_PreviewUI_FileName~"
			)else(
				if maxfilepath != "" then
				(
					Xr_Preview_PreviewName = getFilenameFile maxFileName
				)else(
					Xr_Preview_PreviewName = "UnTitled"
				)

				Xr_Preview_FileName.enabled = false -- Use Scene Preview Name
				Xr_Preview_FileName.text = Xr_Preview_PreviewName
			)
		)

		on Xr_Preview_UseFilePath changed Xr_Preview_UseFilePath_State do
		(
			if Xr_Preview_UseFilePath_State == false then
			(
				Xr_Preview_FilePath.text = Xr_Preview_Lng.getTranslate "~Xr_PreviewUI_FilePath~"
				Xr_Preview_FilePath.enabled = true
				Xr_Preview_Browse.enabled = true
			)else(
				if maxfilepath != "" then
				(
					Xr_Preview_PreviewPath = maxfilepath
				)else(
					Xr_Preview_PreviewPath = "UnTitled"
				)

				Xr_Preview_FilePath.text = Xr_Preview_PreviewPath --获取当前文件的路径和文件名
				Xr_Preview_FilePath.enabled = false
				Xr_Preview_Browse.enabled = false
			)
		)
		
		on Xr_Preview_UpDate pressed do
		(
			if maxfilepath != "" then
			(
				Xr_Preview_PreviewName = getFilenameFile maxFileName
				Xr_Preview_PreviewPath = maxfilepath
			)else(
				Xr_Preview_PreviewName = "UnTitled"
				Xr_Preview_PreviewPath = "UnTitled"
			)
			Xr_Preview_FileName.text = Xr_Preview_PreviewName
			Xr_Preview_FilePath.text = Xr_Preview_PreviewPath
		)

		on Xr_Preview_Browse pressed do
		(
			GetUI_Browse_TextFile = Xr_Preview_Lng.getTranslate "~Xr_PreviewUI_Browse_TextFile~"
			Xr_Preview_TextFile = getSavePath caption:GetUI_Browse_TextFile initialDir:Xr_Preview_FilePath.text
			if Xr_Preview_TextFile != undefined then (Xr_Preview_FilePath.text = Xr_Preview_TextFile + "\\")
		)

		on Xr_Preview_BatchPreview changed Xr_Preview_BatchPreview_state do
		(
			if Xr_Preview_BatchPreview_state == false then
			(
				Xr_Preview_UseFileName.enabled = true
				Xr_Preview_UseFileName.checked = true
				Xr_Preview_BatchValue = 0
			)else(
				Xr_Preview_UseFileName.enabled = false
				Xr_Preview_UseFileName.checked = true
				Xr_Preview_BatchValue = 1
			)
		)
		
		on Xr_Preview_AppStarting changed Xr_Preview_AppStarting_state do
		(
			if Xr_Preview_AppStarting_state == false then
			(
				Xr_Preview_AppStartingValue = 0
			)else(
				Xr_Preview_AppStartingValue = 1
			)
		)
		
		on Xr_Preview_Language pressed do
		(
			if (Xr_StINISetting.Xr_GetINISetting "Xr_PreviewConf" "Lang") == "Zh" then
			(
				Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "Language" "Xr_Preview_English"
				Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "Lang" "En"

			)else(
				
				Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "Language" "Xr_Preview_Chinese"
				Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "Lang" "Zh"
			)
			filein (Xr_Route + "Xr_Preview_Tools.ms")
		)

		on Xr_Preview_Format pressed do
		(
			if Xr_Preview_Format.text == "Avi" then
			(
				Xr_Preview_Format.text = "Mp4"
				Xr_Preview_SetFormat = "Mp4"
				Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "Format" "Mp4"
			)else if Xr_Preview_Format.text == "Mp4" then(
				Xr_Preview_Format.text = "Gif"
				Xr_Preview_SetFormat = "Gif"
				Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "Format" "Gif"
			)else if Xr_Preview_Format.text == "Gif" then(
				Xr_Preview_Format.text = "Avi"
				Xr_Preview_SetFormat = "Avi"
				Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "Format" "Avi"
			)
		)

		on Xr_Preview_Setting pressed do (max preview) --设置拍屏预览参数

		on Xr_Preview_Help pressed do (createDialog Xr_Preview_About)
		on Xr_Preview_SetUpList pressed do (createDialog Xr_Preview_Preset_Win)

	    on Xr_Preview_Run pressed  do
	    (
			while True do
			(
		    	clearSelection()--提前取消选择
		    	try(
					if Xr_Preview_UseFileName.checked == true then
					(
						if maxfilepath != "" then
						(
							Xr_Preview_PreviewName = getFilenameFile maxFileName
						)else(
							Xr_Preview_PreviewName = "UnTitled"
						)
						Xr_Preview_FileName.text = Xr_Preview_PreviewName
					)

					if Xr_Preview_UseFilePath.checked == true then
					(
						if maxfilepath != "" then
						(
							Xr_Preview_PreviewPath = maxfilepath
						)else(
							Xr_Preview_PreviewPath = "UnTitled"
						)
						Xr_Preview_FilePath.text = Xr_Preview_PreviewPath --获取当前文件的路径和文件名
					)

					Xr_Preview_GetPreviewName = Xr_Preview_FileName.text

					if Xr_Preview_GetPreviewName == "UnTitled" or Xr_Preview_GetPreviewName == Xr_Preview_Lng.getTranslate "~Xr_PreviewUI_FileName~" then
					(
						Xr_Popup "~Xr_PreviewUI_GetPreviewName_messageBox~"
						return false
					)

					Xr_Preview_GetPreviewPath = Xr_Preview_FilePath.text

					if Xr_Preview_GetPreviewPath == "UnTitled" or Xr_Preview_GetPreviewPath == Xr_Preview_Lng.getTranslate "~Xr_PreviewUI_FilePath~" then
					(
						Xr_Popup "~Xr_PreviewUI_GetPreviewPath_messageBox~"
						return false
					)

					-- 判断是否点了获取视图 不然拍屏有问题！
					if Xr_Preview_SaveViewInt == 0 then
					(
						Xr_Popup "~Xr_PreviewUI_SaveViewInt_messageBox~"
						return false
					)

				)catch(

					Xr_Popup "~Xr_PreviewUI_Error_messageBox~"
					return false
				)

				if Xr_Preview_AppStartingValue == 0 then
				(
					print (Xr_Preview_Lng.getTranslate "~Xr_PreviewUI_RunPrint~")
					
					if Xr_Preview_BatchValue == 0 then 
					(
						v1.getTM() --获取自定义视图
						Xr_Preview_FN()
						if (keyboard.escPressed) do ( exit )

					)else(

						try(

							XrExportFBX_Max = (maxFilePath as string)+"\\*.max"

							for o in (getfiles (XrExportFBX_Max as string)) do
							(
								loadmaxfile o quiet:true
								Xr_Preview_GetPreviewName = getFilenameFile maxFileName
								v1.getTM() 		--获取自定义视图
								Xr_Preview_FN()        --运行拍屏程序
								if (keyboard.escPressed) do ( exit )
							)

						)catch(

							Xr_Popup "~Xr_PreviewUI_BatchError_messageBox~"
							return false
						)
					)

					OpenViewPath = querybox (Xr_Preview_Lng.getTranslate "~Xr_PreviewUI_OpenViewPath_querybox~") title:"Xr Preview Tools" beep:false
					if OpenViewPath == true then
					(
						shellLaunch (Xr_Preview_GetPreviewPath + "Avi\\") ""
					)

				)else(
					-- 先把自动打开拍屏给关掉
					Xr_MAXIni_FilePath = getMAXIniFile()
					Xr_AutoPlayPreview = getINISetting Xr_MAXIni_FilePath "Performance" "AutoPlayPreview"

					if Xr_AutoPlayPreview == "1" then
					(
						setINISetting Xr_MAXIni_FilePath "Performance" "AutoPlayPreview" "0"
					)

					-- 删除旧缓存文件夹
					if (doesFileExist (Xr_Route + Xr_UploadFileRoute + "Avi")) != false do
					(
						DeleteAvi = "rmdir /s/q \"" + Xr_Route + Xr_UploadFileRoute + "Avi\""
						HiddenDOSCommand DeleteAvi donotwait:true exitCode:&exitcode
					)

					-- 文件名 和 路径 写入配置文件
					Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "NewMaxFileName" (Xr_Preview_GetPreviewName)
					Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "NewMaxfilepath" (Xr_Preview_GetPreviewPath + "Avi\\")

					Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "MaxFileName" (maxFileName)
					Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "Maxfilepath" (maxfilepath)

					Xr_StINISetting.Xr_SetINISetting "Xr_PreviewConf" "BatchValue" (Xr_Preview_BatchValue as string)
					maxVersionS = maxVersion()
					if maxVersionS[1] >= 22000 then
					(
						MaxConvertout = "\"" + getDir #maxroot + "3dsmax.exe\" -q -ma -silent -lang=CHS -safescene=OFF -U MAXScript" + " " + Xr_Route + "Xr_Preview_BackgroundOperation.ms"
					)else(
						MaxConvertout = "\"" + getDir #maxroot + "3dsmax.exe\" -q -ma -silent -lang=CHS -U MAXScript" + " " + Xr_Route + "Xr_Preview_BackgroundOperation.ms"
					)
					HiddenDOSCommand MaxConvertout donotwait:true exitCode:&exitcode
					
					Xr_Popup "~Xr_PreviewUI_AppStarting_messageBox~"
				)
				return false
			)
		)
	)
createdialog Xr_Preview_Tools
)