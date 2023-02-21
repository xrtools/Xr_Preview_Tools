/*****************************************************
***************作者：夏春雨***************************
*************日期：2023.02.07************************
************** QQ：601498315 ***********************
************邮箱：Xr@XrTools.Pro*********************
*****************************************************
*****************************************************/
(
	global Xr_Route = "C:\Maxscript_XrTools\\"
	global Xr_FFmpegFile = Xr_Route + "Conf\ffmpeg.exe" -- ffmpeg路径
	global Xr_UploadFileRoute = "XrTools_UploadFile_Data\\"
	global Xr_Settings_FilePath = Xr_Route + "Conf\\Xr_Settings.ini"
	global Xr_PreviewS_NewMaxfilepath
	global Xr_PreviewS_NewMaxFileName

	-- 获取配置文件
	fn Xr_GetINISetting Xr_GetINI_Section Xr_GetINI_Key = (getINISetting Xr_Settings_FilePath Xr_GetINI_Section Xr_GetINI_Key)

	--- 创建路径 有则忽略 没有则创建
	if doesFileExist (Xr_Route + Xr_UploadFileRoute) == false then
	(
		makeDir  (Xr_Route + Xr_UploadFileRoute)          --总文件夹
	)
	if doesFileExist (Xr_Route + Xr_UploadFileRoute + "Avi") == false then
	(
		makeDir  (Xr_Route + Xr_UploadFileRoute + "Avi")  --存放Avi
	)

	-- 获取保存位置和名称
	Xr_PreviewS_NewMaxfilepath = Xr_GetINISetting "Xr_PreviewConf" "NewMaxfilepath"
	Xr_PreviewS_NewMaxFileName = Xr_GetINISetting "Xr_PreviewConf" "NewMaxFileName"

	-- 文件保存位置没有则创建
	if doesFileExist Xr_PreviewS_NewMaxfilepath == false then (makeDir Xr_PreviewS_NewMaxfilepath)
	
	--获取文件 打开它
	Xr_PreviewS_NamePath = Xr_GetINISetting "Xr_PreviewConf" "maxfilepath" + Xr_GetINISetting "Xr_PreviewConf" "maxFileName"
	loadMaxFile Xr_PreviewS_NamePath useFileUnits:true quiet:true

	fn Xr_PreviewS_FN =
	(
		vpType_string = Xr_GetINISetting "Xr_PreviewConf" "vpType"
		tmMatrix_1_1 = (Xr_GetINISetting "Xr_PreviewConf" "tmMatrix_1_1") as Float
		tmMatrix_1_2 = (Xr_GetINISetting "Xr_PreviewConf" "tmMatrix_1_2") as Float
		tmMatrix_1_3 = (Xr_GetINISetting "Xr_PreviewConf" "tmMatrix_1_3") as Float
		
		tmMatrix_2_1 = (Xr_GetINISetting "Xr_PreviewConf" "tmMatrix_2_1") as Float
		tmMatrix_2_2 = (Xr_GetINISetting "Xr_PreviewConf" "tmMatrix_2_2") as Float
		tmMatrix_2_3 = (Xr_GetINISetting "Xr_PreviewConf" "tmMatrix_2_3") as Float
		
		tmMatrix_3_1 = (Xr_GetINISetting "Xr_PreviewConf" "tmMatrix_3_1") as Float
		tmMatrix_3_2 = (Xr_GetINISetting "Xr_PreviewConf" "tmMatrix_3_2") as Float
		tmMatrix_3_3 = (Xr_GetINISetting "Xr_PreviewConf" "tmMatrix_3_3") as Float
		
		tmMatrix_4_1 = (Xr_GetINISetting "Xr_PreviewConf" "tmMatrix_4_1") as Float
		tmMatrix_4_2 = (Xr_GetINISetting "Xr_PreviewConf" "tmMatrix_4_2") as Float
		tmMatrix_4_3 = (Xr_GetINISetting "Xr_PreviewConf" "tmMatrix_4_3") as Float
	
		tmMatrix = (matrix3 [tmMatrix_1_1,tmMatrix_1_2,tmMatrix_1_3] [tmMatrix_2_1,tmMatrix_2_2,tmMatrix_2_3] [tmMatrix_3_1,tmMatrix_3_2,tmMatrix_3_3] [tmMatrix_4_1,tmMatrix_4_2,tmMatrix_4_3])
		vpType = execute ("#" + vpType_string)
		viewport.setType vpType
		viewport.setTM tmMatrix

		--设置渲染尺寸
		Xr_Preview_RenderWidthValue = Xr_GetINISetting "Xr_PreviewConf" "RenderWidthValue"
		Xr_Preview_RenderHeightValue = Xr_GetINISetting "Xr_PreviewConf" "RenderHeightValue"
		renderWidth = Xr_Preview_RenderWidthValue as Integer
		renderHeight = Xr_Preview_RenderHeightValue as Integer
		renderSceneDialog.Update()

		-- 只显示模型
		hideByCategory.geometry = false
		hideByCategory.shapes = true
		hideByCategory.lights = true
		hideByCategory.cameras = true
		hideByCategory.helpers = true
		hideByCategory.spacewarps = true
		hideByCategory.particles = true
		hideByCategory.bones = true

		Xr_Preview_ScreenPreferencesValue = Xr_GetINISetting "Xr_PreviewConf" "ScreenPresetsList"
		-- "12"高质量 "13"标准 "14"性能 "15"DX 模式
		Xr_Preview_ExecuteAction2Value = #("12","13","14","15")
		actionMan.executeAction -844228238 (Xr_Preview_ExecuteAction2Value[Xr_Preview_ScreenPreferencesValue as integer] as string)

		Xr_Preview_ScreenPresetsValue = Xr_GetINISetting "Xr_PreviewConf" "ScreenPreferencesList"
		--"63566"默认明暗处理  "553"面  "556"边界框 "554"一致性颜色 "40834"隐藏线 "616"粘土
		Xr_Preview_ExecuteAction1Value = #("63566","553","556","554","40834","616")
		actionMan.executeAction 0 (Xr_Preview_ExecuteAction1Value[Xr_Preview_ScreenPresetsValue as integer] as string)

		actionMan.executeAction 0 "618"  -- Tools: 使用纯色切换
		actionMan.executeAction 0 "40264"  -- Views: 专家模式切换

		--获取当前文件起始结束帧
		Xr_PreviewStart = (animationRange.start.frame as integer)   
		Xr_PreviewEnd = (animationRange.end.frame as integer)

		Xr_PreviewS_NamePath = Xr_Route + Xr_UploadFileRoute + "Avi\\" + getFilenameFile maxFileName + ".avi"

		videoout = Xr_PreviewS_NewMaxfilepath + Xr_PreviewS_NewMaxFileName

		-- 导出前先清理旧文件
		if doesFileExist Xr_PreviewS_NamePath == true then 
		(
			CreatefilePathb = createfile Xr_PreviewS_NamePath
			close CreatefilePathb
			deletefile Xr_PreviewS_NamePath
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

		anim_bmp = bitmap renderWidth renderHeight filename:Xr_PreviewS_NamePath

		for t = Xr_PreviewStart to Xr_PreviewEnd do
		(
			sliderTime = t
			dib = gw.getViewportDib()
			copy dib anim_bmp
			save anim_bmp
		)

		save anim_bmp
		close anim_bmp
		gc()

		Xr_PreviewS_SetFormat = Xr_GetINISetting "Xr_PreviewConf" "Format"
		if Xr_PreviewS_SetFormat == "Avi" then
		(
			FFmpeg_SetFormat = " -vcodec h264 -pix_fmt yuv420p " + "\"" + (videoout + ".avi")
		)else if Xr_PreviewS_SetFormat == "Mp4" then
		(
			FFmpeg_SetFormat = " -c:v libx264 -pix_fmt yuv420p " + "\"" + (videoout + ".mp4")
		)else if Xr_PreviewS_SetFormat == "Gif" then
		(
			FFmpeg_SetFormat = " -filter_complex \"[0]split[a][b]; [a]palettegen[palette]; [b][palette]paletteuse\" " + "\"" + (videoout + ".gif")
		)else(FFmpeg_SetFormat = "\"" + (videoout + ".mp4"))

		convertout = Xr_FFmpegFile + " -i \"" + Xr_PreviewS_NamePath + "\"" + FFmpeg_SetFormat + "\"" + " -y -loglevel quiet"
		HiddenDOSCommand convertout donotwait:true exitCode:&exitcode
	)

	while True do
	(
		print "Xr: 多按几下 ESC 即可中断取消~"
		clearSelection()--提前取消选择

		Xr_PreviewS_BatchValue = Xr_GetINISetting "Xr_PreviewConf" "BatchValue"
		if Xr_PreviewS_BatchValue == "0" then 
		(
			Xr_PreviewS_FN()
			if (keyboard.escPressed) do ( exit )
		)else(
			try(
				XrExportFBX_Max = (maxFilePath as string)+"\\*.max"

				for o in (getfiles (XrExportFBX_Max as string)) do
				(
					loadmaxfile o quiet:true
					Xr_PreviewS_NewMaxFileName = getFilenameFile maxFileName
					Xr_PreviewS_FN()        --运行拍屏程序
					if (keyboard.escPressed) do ( exit )
				)
			)catch(
				messageBox "批量拍屏运行出错！ " title:"Xr Preview Tools" beep:false
				exit
			)
		)
		exit
	)

	convertoutOK = "msg %username% /time:10 " + "后台拍屏已完成！"
	HiddenDOSCommand convertoutOK donotwait:true exitCode:&exitcode
	quitMax #noPrompt
)