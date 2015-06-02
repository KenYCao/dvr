' ####################################################################
' VBScript Sub Procedure
'	to convert Excel 2003 xml spreadsheet to .xlsx file format
'	created on 2014/07/03 by Ken Cao (yong.cao@q2bi.com)
' Paramter:
'	config: confguration file full path name
'   tempDir: temporary directory to save csv file
' ####################################################################

Sub saveAS(infile, outpath)
	Dim objExcel 
	Dim xmlwb 

	' create an excel application object
	Set objExcel = CreateObject("Excel.Application")

	' invisible and suppress message
	objExcel.Visible = False
	objExcel.DisplayAlerts = False

	' open configuration file
	Set xmlwb = objExcel.Workbooks.Open(infile)


	xmlwb.SaveAs outpath & "\" & Left(xmlwb.name,Len(xmlwb.name)-4) & ".xlsx", 51
	' close opened workbook and quit excel application
	objExcel.ActiveWorkbook.Close
	objExcel.Quit

	' release memorary
	Set objExcel = Nothing
End Sub