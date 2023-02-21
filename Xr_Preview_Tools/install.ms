/*****************************************************
***************作者：夏春雨***************************
*************日期：2023.02.07************************
***************QQ：601498315************************
************邮箱：Xr@XrTools.Pro*********************
*****************************************************
*****************************************************/
(
	global Xr_Preview_install_Tools
	global script_founded = false
	global path_installer = getDir #temp + @"\XrTools_Installer"
	global tools_path = "Maxscript_XrTools"
	global path_script = @"C:\Maxscript_XrTools\"
	global PreviewTools_script = path_script + "Xr_Preview_Tools.ms"
	global PreviewBackgroundOperation_script = path_script + "Xr_Preview_BackgroundOperation.ms"
	global Previewffmpeg_script = path_script + @"Conf\ffmpeg.exe"
	global PreviewCH_script = path_script + @"Conf\Xr_Preview_Chinese.lng"
	global PreviewEN_script = path_script + @"Conf\Xr_Preview_English.lng"
	global PreviewToolsIMG1_script = path_script + @"img\Xr_ExportFile_Tools\bip_general_i.bmp"
	global PreviewToolsIMG2_script = path_script + @"img\Xr_ExportFile_Tools\UVWUnwrapModes_16a.bmp"
	global PreviewToolsIMG3_script = path_script + @"img\Xr_ExportFile_Tools\UVWUnwrapModes_16i.bmp"
	global PreviewToolsIMG4_script = path_script + @"img\Xr_ExportFile_Tools\PhysX_Main_24a.bmp"
	global PreviewToolsIMG5_script = path_script + @"img\Xr_ExportFile_Tools\PhysX_Main_24i.bmp"
	global Xr_Preview_LitView_AttachArrayWhole = #()

	try(DestroyDialog Xr_Preview_install_Tools)catch()
	------ 弹窗
	fn Xr_Popup PopupText = (messageBox PopupText title:"Xr ExportFile Tools" beep:false)
	------ 新建文件夹
	fn Xr_NewFolder NewFolderText = (if (doesFileExist NewFolderText) == false then ( makeDir NewFolderText))
	------ 拷贝
	fn Xr_NewCopyFile NewCopyFileText CopyTargetFileText = (if (doesFileExist NewCopyFileText) == true then (copyFile NewCopyFileText CopyTargetFileText))
	------ 删除
	fn Xr_DelFile DelFileText = (if (doesFileExist DelFileText) == true then ( deleteFile DelFileText))

	rollout Xr_Preview_install_Tools "Xr Preview Install" width:400 height:240
	(
		dotNetControl Xr_Preview_install_Label_1 "System.Windows.Forms.Label" pos:[0,0] width:400 height:33
		dotNetControl Xr_Preview_install_Label_2 "System.Windows.Forms.Label" pos:[0,33] width:400 height:20
		GroupBox Xr_Preview_Grb1 "" pos:[10,52] width:380 height:120
		label Xr_Preview_Lab_1 "Xr_Preview_Tools是一个拍屏插件.\n\n使用插件拍屏的文件大小会比Max拍出来的小很多倍,\n\n并且可以设置后台拍屏,不会占用当前Max." pos:[70,72] width:300 height:70
		HyperLink Xr_Preview_installWeb "使用文档" pos:[330,153] width:135 height:15 color:(color 255 5 122) hovercolor:(color 74 99 122) visitedcolor:(color 190 0 0) address:"https://xrtools.pro/index.php/109.html"
		button Xr_Preview_install "Install" pos:[10,180] width:315 height:50
		button Xr_Preview_Update "更新/修复" pos:[330,181] width:60 height:23
		button Xr_Preview_uninstall "Uninstall" pos:[330,205] width:60 height:23

		on Xr_Preview_install_Tools open do
		(
			bold = (dotnetclass "System.Drawing.FontStyle").Bold
			align = dotNetClass "HorizontalAlignment"
			Xr_Preview_install_Label_1.text = "Xr Preview Install"
			Xr_Preview_install_Label_1.font = dotnetobject "System.Drawing.Font" "微软雅黑" 16 bold
			Xr_Preview_install_Label_1.backcolor = Xr_Preview_install_Label_1.backcolor.fromARGB 136 214 210
			Xr_Preview_install_Label_1.foreColor = Xr_Preview_install_Label_1.backcolor.fromARGB 0 0 0
			Xr_Preview_install_Label_1.TextAlign = (dotNetClass "System.Drawing.ContentAlignment").MiddleCenter

			Xr_Preview_install_Label_2.text = "--- TG Xr ---"
			Xr_Preview_install_Label_2.backcolor = Xr_Preview_install_Label_2.backcolor.fromARGB 176 176 176
			Xr_Preview_install_Label_2.foreColor = Xr_Preview_install_Label_2.backcolor.fromARGB 90 90 90
			Xr_Preview_install_Label_2.font = dotnetobject "System.Drawing.Font" "微软雅黑" 9
			Xr_Preview_install_Label_2.font = dotnetobject "System.Drawing.Font" "微软雅黑" 9 bold
			Xr_Preview_install_Label_2.TextAlign = (dotNetClass "System.Drawing.ContentAlignment").MiddleCenter
			
			while True do
			(
				try(
					-- 从注册表查找当前安装了哪些版本Max
					reg = dotNetClass "Microsoft.Win32.Registry"
					GetMaxRegistry = reg.LocalMachine.OpenSubKey @"Software\Autodesk\3dsMax"
					
					for GetMaxValue in GetMaxRegistry.GetSubKeyNames() do
					(
						Xr_Preview_LitView_SummaryData = #()
						maxFile = (GetMaxRegistry.OpenSubKey GetMaxValue).GetValue "Location"
						MaxName = (GetMaxRegistry.OpenSubKey GetMaxValue).GetValue "ProductName"
						-- 如果为 undefined 那就是卸载了 注册表还有残留，没有卸载是有Location（Max安装路径） 和 ProductName（Max版本）两个值得.
						if maxFile != undefined and MaxName != undefined then
						(
							try(XrUploadConf_MaxName = FilterString MaxName " ")catch()
							append Xr_Preview_LitView_SummaryData (XrUploadConf_MaxName[3] + " " + XrUploadConf_MaxName[4])
							append Xr_Preview_LitView_SummaryData maxFile
							append Xr_Preview_LitView_AttachArrayWhole Xr_Preview_LitView_SummaryData
						)
					)
				)catch(
					Xr_Popup ("Max版本检测失败！" + getCurrentException())
					return false
				)

				try(
					-- 检测解压的临时文件夹
					if (doesFileExist path_installer) == false then 
					(
						Xr_Popup "获取临时安装文件夹失败！"
						Xr_Preview_install_Tools.Xr_Preview_install.enabled = false
						Xr_Preview_install_Tools.Xr_Preview_uninstall.enabled = false
						Xr_Preview_install_Tools.Xr_Preview_Update.enabled = false
						return false
					)
					-- 判断是否已经有安装过
					if (doesFileExist PreviewTools_script) == true and (doesFileExist PreviewBackgroundOperation_script) == true then
					(
						script_founded = true
						Xr_Preview_install_Tools.Xr_Preview_install.enabled = false
						Xr_Preview_install_Tools.Xr_Preview_uninstall.enabled = true
						if (doesFileExist path_script) == true then
						(
							Xr_Preview_install_Tools.Xr_Preview_Update.enabled = true
						)else(
							Xr_Preview_install_Tools.Xr_Preview_Update.enabled = false
						)
					)else(
						script_founded = false
						Xr_Preview_install_Tools.Xr_Preview_install.enabled = true
						Xr_Preview_install_Tools.Xr_Preview_uninstall.enabled = false
						if (doesFileExist path_script) == true then
						(
							Xr_Preview_install_Tools.Xr_Preview_Update.enabled = true
						)else(
							Xr_Preview_install_Tools.Xr_Preview_Update.enabled = false
						)
					)
				)catch(
					Xr_Popup ("初始化检测失败！" + getCurrentException())
					return false
				)
				return false
			)
		)
		fn Xr_Preview_installFN =
		(
			-- 判断新增文件夹
			Xr_NewFolder (path_script)
			Xr_NewFolder (path_script + "Conf")
			Xr_NewFolder (path_script + "img")
			Xr_NewFolder (path_script + "Install")
			Xr_NewFolder (path_script + "XrTools_UploadFile_Data")
			Xr_NewFolder (path_script + @"XrTools_UploadFile_Data\Avi")
			Xr_NewFolder (path_script + @"XrTools_UploadFile_Data\Max")
			Xr_NewFolder (path_script + @"img\Xr_ExportFile_Tools")
			-- 拷贝文件
			PreviewTools_Temp = path_installer + @"\Maxscript_XrTools\Xr_Preview_Tools.ms"
			Xr_NewCopyFile PreviewTools_Temp PreviewTools_script

			PreviewBackgroundOperation_Temp = path_installer + @"\Maxscript_XrTools\Xr_Preview_BackgroundOperation.ms"
			Xr_NewCopyFile PreviewBackgroundOperation_Temp PreviewBackgroundOperation_script

			PreviewMenu_Temp = path_installer + @"\Maxscript_XrTools\Xr_Preview_Macro.ms"
			Xr_NewCopyFile PreviewMenu_Temp (path_script + "Xr_Preview_Macro.ms")

			Previewffmpeg_Temp = path_installer + @"\Maxscript_XrTools\Conf\ffmpeg.exe"
			Xr_NewCopyFile Previewffmpeg_Temp Previewffmpeg_script

			PreviewCH_Temp = path_installer + @"\Maxscript_XrTools\Conf\Xr_Preview_Chinese.lng"
			Xr_NewCopyFile PreviewCH_Temp PreviewCH_script

			PreviewEN_Temp = path_installer + @"\Maxscript_XrTools\Conf\Xr_Preview_English.lng"
			Xr_NewCopyFile PreviewEN_Temp PreviewEN_script

			PreviewToolsIMG1_Temp = path_installer + @"\Maxscript_XrTools\img\Xr_ExportFile_Tools\bip_general_i.bmp"
			Xr_NewCopyFile PreviewToolsIMG1_Temp PreviewToolsIMG1_script

			PreviewToolsIMG2_Temp = path_installer + @"\Maxscript_XrTools\img\Xr_ExportFile_Tools\UVWUnwrapModes_16a.bmp"
			Xr_NewCopyFile PreviewToolsIMG2_Temp PreviewToolsIMG2_script

			PreviewToolsIMG3_Temp = path_installer + @"\Maxscript_XrTools\img\Xr_ExportFile_Tools\UVWUnwrapModes_16i.bmp"
			Xr_NewCopyFile PreviewToolsIMG3_Temp PreviewToolsIMG3_script

			PreviewToolsIMG4_Temp = path_installer + @"\Maxscript_XrTools\img\Xr_ExportFile_Tools\PhysX_Main_24a.bmp"
			Xr_NewCopyFile PreviewToolsIMG4_Temp PreviewToolsIMG4_script

			PreviewToolsIMG5_Temp = path_installer + @"\Maxscript_XrTools\img\Xr_ExportFile_Tools\PhysX_Main_24i.bmp"
			Xr_NewCopyFile PreviewToolsIMG5_Temp PreviewToolsIMG5_script

			Xr_Preview_install_Tools.Xr_Preview_install.enabled = false
			Xr_Preview_install_Tools.Xr_Preview_uninstall.enabled = false

			-- 多版本判断安装
			PreviewTools_Temp = path_installer + @"\Maxscript_XrTools\Install\Xr_Preview_Menu.ms"
			Xr_NewCopyFile PreviewTools_Temp (path_script + @"Install\Xr_Preview_Menu.ms")

			Del_PreviewTools_Temp = path_installer + @"\Maxscript_XrTools\Install\Xr_Preview_MenuDel.ms"
			Xr_NewCopyFile Del_PreviewTools_Temp (path_script + @"Install\Xr_Preview_MenuDel.ms")

			if (doesFileExist PreviewTools_Temp) == true then
			(
				for m = 1 to Xr_Preview_LitView_AttachArrayWhole.count do
				(
					if (doesFileExist (Xr_Preview_LitView_AttachArrayWhole[m][2] + @"scripts\Startup\Xr_Preview_Menu.ms")) == false then
					(
						copyFile PreviewTools_Temp (Xr_Preview_LitView_AttachArrayWhole[m][2] + @"scripts\Startup\Xr_Preview_Menu.ms")
					)else(
						Xr_DelFile (Xr_Preview_LitView_AttachArrayWhole[m][2] + @"scripts\Startup\Xr_Preview_Menu.ms")
						copyFile PreviewTools_Temp (Xr_Preview_LitView_AttachArrayWhole[m][2] + @"scripts\Startup\Xr_Preview_Menu.ms")
					)
					if (doesFileExist (Xr_Preview_LitView_AttachArrayWhole[m][2] + @"scripts\Startup\Xr_Preview_MenuDel.ms")) == true then
					(
						Xr_DelFile (Xr_Preview_LitView_AttachArrayWhole[m][2] + @"scripts\Startup\Xr_Preview_MenuDel.ms")
					)
				)
			)
			--添加菜单栏
			try(filein (@"C:\Maxscript_XrTools\Xr_Preview_Macro.ms"))catch()
			-- 查询是否已经有了菜单
			if (menuMan.findMenu "XrTools") == undefined do
			(
				theMainMenu = menuMan.getMainMenuBar() --获取主菜单栏
				theMenu = menuMan.createMenu "XrTools" --创建菜单
				theSubMenu = menuMan.createSubMenuItem "XrTools" theMenu --创建子菜单项
				theMainMenu.addItem theSubMenu (theMainMenu.numItems()+1) --将子菜单添加到主菜单
				theActionPreview = menuMan.createActionItem "Preview_Tools" "XrTools" --从MacroScript创建ActionItem
				separator = menuMan.createSeparatorItem()
				theActionOpenFolderFile = menuMan.createActionItem "OpenFolderFile_Tools" "XrTools" --从MacroScript创建ActionItem
				theMenu.addItem theActionPreview (theMenu.numItems()+1) --将ActionItem添加到菜单
				theMenu.addItem separator (theMenu.numItems()+1) --将ActionItem添加到菜单
				theMenu.addItem theActionOpenFolderFile (theMenu.numItems()+1) --将ActionItem添加到菜单
				menuMan.updateMenuBar() --更新菜单栏
			)
		)
		fn Xr_Preview_uninstallFN =
		(
			-- 查询是否已经有了菜单 有了就删掉
			lMenu = menuMan.findMenu "XrTools"
			if lMenu != undefined do
			(
				menuMan.unRegisterMenu lMenu
				menuMan.updateMenuBar()
				lMenu = menuMan.findMenu "XrTools" 
			)

			Del_PreviewTools_Temp = path_installer + @"\Maxscript_XrTools\Install\Xr_Preview_MenuDel.ms"
			deleteFile (path_script + @"Install\Xr_Preview_Menu.ms")
			deleteFile (path_script + @"Install\Xr_Preview_MenuDel.ms")
			if (doesFileExist Del_PreviewTools_Temp) == true then
			(
				for m = 1 to Xr_Preview_LitView_AttachArrayWhole.count do
				(
					if (doesFileExist (Xr_Preview_LitView_AttachArrayWhole[m][2] + @"scripts\Startup\Xr_Preview_MenuDel.ms")) == false then
					(
						copyFile Del_PreviewTools_Temp (Xr_Preview_LitView_AttachArrayWhole[m][2] + @"scripts\Startup\Xr_Preview_MenuDel.ms")
					)else(
						Xr_DelFile (Xr_Preview_LitView_AttachArrayWhole[m][2] + @"scripts\Startup\Xr_Preview_MenuDel.ms")
						copyFile Del_PreviewTools_Temp (Xr_Preview_LitView_AttachArrayWhole[m][2] + @"scripts\Startup\Xr_Preview_MenuDel.ms")
					)
					if (doesFileExist (Xr_Preview_LitView_AttachArrayWhole[m][2] + @"scripts\Startup\Xr_Preview_Menu.ms")) == true then
					(
						Xr_DelFile (Xr_Preview_LitView_AttachArrayWhole[m][2] + @"scripts\Startup\Xr_Preview_Menu.ms")
					)
				)
			)

			Xr_DelFile (path_script + "Xr_Preview_Macro.ms")
			Xr_DelFile PreviewTools_script
			Xr_DelFile PreviewBackgroundOperation_script

			if (doesFileExist Previewffmpeg_script) == true then
			(
				if (doesFileExist (path_script + "Xr_ExportFile_Tools.ms")) == false then
				(
					deleteFile Previewffmpeg_script
				)
			)

			if (doesFileExist PreviewToolsIMG1_script) == true then
			(
				if (doesFileExist (path_script + "Xr_ExportFile_Tools.ms")) == false then
				(
					deleteFile PreviewToolsIMG1_script
				)
			)
			if (doesFileExist PreviewToolsIMG2_script) == true then
			(
				if (doesFileExist (path_script + "Xr_ExportFile_Tools.ms")) == false then
				(
					deleteFile PreviewToolsIMG2_script
				)
			)
			if (doesFileExist PreviewToolsIMG3_script) == true then
			(
				if (doesFileExist (path_script + "Xr_ExportFile_Tools.ms")) == false then
				(
					deleteFile PreviewToolsIMG3_script
				)
			)
			if (doesFileExist PreviewToolsIMG4_script) == true then
			(
				if (doesFileExist (path_script + "Xr_ExportFile_Tools.ms")) == false then
				(
					deleteFile PreviewToolsIMG4_script
				)
			)
			if (doesFileExist PreviewToolsIMG5_script) == true then
			(
				if (doesFileExist (path_script + "Xr_ExportFile_Tools.ms")) == false then
				(
					deleteFile PreviewToolsIMG5_script
				)
			)
			if (doesFileExist path_script) == true do 
			(
				files = getFiles (path_script + @"Conf\" + "*.*")
				
				for d = 1 to files.count do
				(
					if files[d] == @"C:\Maxscript_XrTools\Conf\ffmpeg.exe" then 
					(
						deleteFile @"C:\Maxscript_XrTools\Conf\ffmpeg.exe"
					)
					if files[d] == @"C:\Maxscript_XrTools\Conf\Xr_Preview_Chinese.lng" then 
					(
						deleteFile @"C:\Maxscript_XrTools\Conf\Xr_Preview_Chinese.lng"
					)
					if files[d] == @"C:\Maxscript_XrTools\Conf\Xr_Preview_English.lng" then 
					(
						deleteFile @"C:\Maxscript_XrTools\Conf\Xr_Preview_English.lng"
					)
				)
			)
			if (doesFileExist (path_script + "Conf")) == true do 
			(
				files = getFiles (path_script + @"Conf\*.*")
				if files.count == 0 do 
				(
					DelConfTemp = "rmdir /s/q \"" + path_script + "Conf" + "\""
					HiddenDOSCommand DelConfTemp donotwait:true exitCode:&exitcode
				)
			)
			if (doesFileExist (path_script + @"img\Xr_ExportFile_Tools")) == true do 
			(
				files = getFiles (path_script + @"img\Xr_ExportFile_Tools\*.*")
				if files.count == 0 do 
				(
					DelimgTemp = "rmdir /s/q \"" + path_script + @"img\Xr_ExportFile_Tools" + "\""
					HiddenDOSCommand DelimgTemp donotwait:true exitCode:&exitcode
				)
			)
			if (doesFileExist path_script) == true do 
			(
				files = getFiles (path_script + "*.*")
				if files.count == 0 do 
				(
					DelTemp = "rmdir /s/q \"" + path_script + "\""
					HiddenDOSCommand DelTemp donotwait:true exitCode:&exitcode
				)
			)
		)
		on Xr_Preview_install pressed do 
		(
			try 
			(
				Xr_Preview_installFN()
				Xr_Popup "安装完成！"
				DestroyDialog Xr_Preview_install_Tools
			)catch(
				Xr_Popup ("安装出现错误 安装失败！" + (getCurrentException()))
			)
		)
		on Xr_Preview_uninstall pressed do 
		(
			try 
			(
				Xr_Preview_uninstallFN()
				Xr_Popup "卸载完成！"
				DestroyDialog Xr_Preview_install_Tools
			)catch(
				Xr_Popup ("卸载失败！" + (getCurrentException()))
			)
		)

		on Xr_Preview_Update pressed do 
		(
			try 
			(
				if (doesFileExist path_script) == true do
				(
					-- 判断新增文件夹
					Xr_NewFolder (path_script + "Conf")
					Xr_NewFolder (path_script + "img")
					Xr_NewFolder (path_script + "Install")
					Xr_NewFolder (path_script + "XrTools_UploadFile_Data")
					Xr_NewFolder (path_script + @"XrTools_UploadFile_Data\Avi")
					Xr_NewFolder (path_script + @"XrTools_UploadFile_Data\Max")
					Xr_NewFolder (path_script + @"img\Xr_ExportFile_Tools")

					Xr_DelFile (path_script + "Xr_Preview_Macro.ms")
					PreviewMenu_Temp = path_installer + @"\Maxscript_XrTools\Xr_Preview_Macro.ms"
					Xr_NewCopyFile PreviewMenu_Temp (path_script + "Xr_Preview_Macro.ms")

					Xr_DelFile PreviewTools_script
					PreviewTools_Temp = path_installer + @"\Maxscript_XrTools\Xr_Preview_Tools.ms"
					Xr_NewCopyFile PreviewTools_Temp PreviewTools_script

					Xr_DelFile PreviewBackgroundOperation_script
					PreviewBackgroundOperation_Temp = path_installer + @"\Maxscript_XrTools\Xr_Preview_BackgroundOperation.ms"
					Xr_NewCopyFile PreviewBackgroundOperation_Temp PreviewBackgroundOperation_script

					-- 多版本判断安装
					PreviewTools_Temp = path_installer + @"\Maxscript_XrTools\Install\Xr_Preview_Menu.ms"
					Del_PreviewTools_Temp = path_installer + @"\Maxscript_XrTools\Install\Xr_Preview_MenuDel.ms"

					deleteFile (path_script + @"Install\Xr_Preview_Menu.ms")
					deleteFile (path_script + @"Install\Xr_Preview_MenuDel.ms")

					Xr_NewCopyFile PreviewTools_Temp (path_script + @"Install\Xr_Preview_Menu.ms")
					Xr_NewCopyFile Del_PreviewTools_Temp (path_script + @"Install\Xr_Preview_MenuDel.ms")
					
					if (doesFileExist PreviewTools_Temp) == true then
					(
						for m = 1 to Xr_Preview_LitView_AttachArrayWhole.count do
						(
							if (doesFileExist (Xr_Preview_LitView_AttachArrayWhole[m][2] + @"scripts\Startup\Xr_Preview_Menu.ms")) == false then
							(
								copyFile PreviewTools_Temp (Xr_Preview_LitView_AttachArrayWhole[m][2] + @"scripts\Startup\Xr_Preview_Menu.ms")
							)else(
								Xr_DelFile (Xr_Preview_LitView_AttachArrayWhole[m][2] + @"scripts\Startup\Xr_Preview_Menu.ms")
								copyFile PreviewTools_Temp (Xr_Preview_LitView_AttachArrayWhole[m][2] + @"scripts\Startup\Xr_Preview_Menu.ms")
							)
							if (doesFileExist (Xr_Preview_LitView_AttachArrayWhole[m][2] + @"scripts\Startup\Xr_Preview_MenuDel.ms")) == true then
							(
								Xr_DelFile (Xr_Preview_LitView_AttachArrayWhole[m][2] + @"scripts\Startup\Xr_Preview_MenuDel.ms")
							)
						)
					)

					files = getFiles (path_script + @"Conf\" + "*.*")
					for d = 1 to files.count do
					(
						if files[d] == @"C:\Maxscript_XrTools\Conf\ffmpeg.exe" then 
						(
							deleteFile @"C:\Maxscript_XrTools\Conf\ffmpeg.exe"
						)
						if files[d] == @"C:\Maxscript_XrTools\Conf\Xr_Preview_Chinese.lng" then 
						(
							deleteFile @"C:\Maxscript_XrTools\Conf\Xr_Preview_Chinese.lng"
						)
						if files[d] == @"C:\Maxscript_XrTools\Conf\Xr_Preview_English.lng" then 
						(
							deleteFile @"C:\Maxscript_XrTools\Conf\Xr_Preview_English.lng"
						)
					)

					Previewffmpeg_Temp = path_installer + @"\Maxscript_XrTools\Conf\ffmpeg.exe"
					Xr_NewCopyFile Previewffmpeg_Temp Previewffmpeg_script

					PreviewCH_Temp = path_installer + @"\Maxscript_XrTools\Conf\Xr_Preview_Chinese.lng"
					Xr_NewCopyFile PreviewCH_Temp PreviewCH_script

					PreviewEN_Temp = path_installer + @"\Maxscript_XrTools\Conf\Xr_Preview_English.lng"
					Xr_NewCopyFile PreviewEN_Temp PreviewEN_script

					if (doesFileExist PreviewToolsIMG1_script) == true then
					(
						if (doesFileExist (path_script + "Xr_ExportFile_Tools.ms")) == false then
						(
							deleteFile PreviewToolsIMG1_script
						)
					)
					if (doesFileExist PreviewToolsIMG2_script) == true then
					(
						if (doesFileExist (path_script + "Xr_ExportFile_Tools.ms")) == false then
						(
							deleteFile PreviewToolsIMG2_script
						)
					)
					if (doesFileExist PreviewToolsIMG3_script) == true then
					(
						if (doesFileExist (path_script + "Xr_ExportFile_Tools.ms")) == false then
						(
							deleteFile PreviewToolsIMG3_script
						)
					)
					if (doesFileExist PreviewToolsIMG4_script) == true then
					(
						if (doesFileExist (path_script + "Xr_ExportFile_Tools.ms")) == false then
						(
							deleteFile PreviewToolsIMG4_script
						)
					)
					if (doesFileExist PreviewToolsIMG5_script) == true then
					(
						if (doesFileExist (path_script + "Xr_ExportFile_Tools.ms")) == false then
						(
							deleteFile PreviewToolsIMG5_script
						)
					)

					PreviewToolsIMG1_Temp = path_installer + @"\Maxscript_XrTools\img\Xr_ExportFile_Tools\bip_general_i.bmp"
					Xr_NewCopyFile PreviewToolsIMG1_Temp PreviewToolsIMG1_script

					PreviewToolsIMG2_Temp = path_installer + @"\Maxscript_XrTools\img\Xr_ExportFile_Tools\UVWUnwrapModes_16a.bmp"
					Xr_NewCopyFile PreviewToolsIMG2_Temp PreviewToolsIMG2_script

					PreviewToolsIMG3_Temp = path_installer + @"\Maxscript_XrTools\img\Xr_ExportFile_Tools\UVWUnwrapModes_16i.bmp"
					Xr_NewCopyFile PreviewToolsIMG3_Temp PreviewToolsIMG3_script

					PreviewToolsIMG4_Temp = path_installer + @"\Maxscript_XrTools\img\Xr_ExportFile_Tools\PhysX_Main_24a.bmp"
					Xr_NewCopyFile PreviewToolsIMG4_Temp PreviewToolsIMG4_script

					PreviewToolsIMG5_Temp = path_installer + @"\Maxscript_XrTools\img\Xr_ExportFile_Tools\PhysX_Main_24i.bmp"
					Xr_NewCopyFile PreviewToolsIMG5_Temp PreviewToolsIMG5_script


					Xr_Popup "修复更新完成！"
					DestroyDialog Xr_Preview_install_Tools
				)
			)catch(
				Xr_Popup ("修复更新失败！" + (getCurrentException()))
			)
		)

		on Xr_Preview_install_Tools close do
		(
			if (doesFileExist path_installer) != false do 
			(
				try(
					DeleteinstallerTemp = "rmdir /s/q \"" + path_installer + "\""
					HiddenDOSCommand DeleteinstallerTemp donotwait:true exitCode:&exitcode
				)catch(
					Xr_Popup ("缓存清理失败！" + (getCurrentException()))
				)
			)
		)
	)
	createdialog Xr_Preview_install_Tools
)