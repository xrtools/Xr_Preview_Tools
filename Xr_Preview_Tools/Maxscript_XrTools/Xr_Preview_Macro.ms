(
	macroScript Preview_Tools
	category:"XrTools"
	buttonText:"��������"
	toolTip:"��������"
	(
		on execute do
		(
            try(
            	filein (@"C:\Maxscript_XrTools\Xr_Preview_Tools.ms")
            )catch(
            	messagebox "��ʧ�ܳ���δ֪����" beep:false
            )
		)
	)
	
	macroScript OpenFolderFile_Tools
	category:"XrTools"
	buttonText:"�򿪵�ǰ�ļ��ļ���"
	toolTip:"�򿪵�ǰ�ļ����ڵ��ļ���"
	(
		on execute do
		(
            try(
            	ShellLaunch maxfilepath ""
            )catch(
            	messagebox "��ʧ�ܳ���δ֪����" beep:false
            )
		)
	)
)