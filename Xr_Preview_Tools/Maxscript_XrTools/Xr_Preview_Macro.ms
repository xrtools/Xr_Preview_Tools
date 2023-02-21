(
	macroScript Preview_Tools
	category:"XrTools"
	buttonText:"拍屏工具"
	toolTip:"拍屏工具"
	(
		on execute do
		(
            try(
            	filein (@"C:\Maxscript_XrTools\Xr_Preview_Tools.ms")
            )catch(
            	messagebox "打开失败出现未知错误！" beep:false
            )
		)
	)
	
	macroScript OpenFolderFile_Tools
	category:"XrTools"
	buttonText:"打开当前文件文件夹"
	toolTip:"打开当前文件所在的文件夹"
	(
		on execute do
		(
            try(
            	ShellLaunch maxfilepath ""
            )catch(
            	messagebox "打开失败出现未知错误！" beep:false
            )
		)
	)
)