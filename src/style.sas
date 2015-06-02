/***********************************************************************************************************
 Program: style.sas
    @Author: Ken Cao (yong.cao@q2bi.com)
    @Initial Date: 2015/02/23

 
  This program creates style template for Q2 data validation report.



 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 Paramter: 


 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 Revision History:


 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 Example:



***********************************************************************************************************/


proc template;                                                                
    define style styles.dvrstyle;
    parent = styles.sasweb;

    class colors / 
        /* 'headerbg' = cx3D897C */
        'headerbg' = cx4FADA1
        'headerfg' = cxFFFFFF
        'bodyfg' = cx555555
        'skipcolor' = cxE7EFEE
        'breakcolor' = cxA9D08E
        'breakfg' = cxFFFFFF
        'titlecolor' = cx707070
    ;

    class fonts /
/*        'font'  = ("Segoe UI, Helvetica, Arial, sans-serif")*/
        'font'  = ("Segoe UI")
    ;
    
    class Container /
        font = fonts("font")
        fontsize = 10pt
    ;

    class HeadersAndFooters /
        font = fonts("font")
        fontsize = 10pt
    ;

    class Header /
        backgroundcolor = colors('headerbg')
        foreground = colors('headerfg')
        fontweight = bold
    ;


    class Data /
        foreground = colors('bodyfg')
    ;


    class SystemTitle/
        just = center
        font = fonts("font")
        fontweight = bold
        fontsize = 14pt
        height = 20pt
        foreground = colors('titlecolor')
    ;

    class SystemTitle2/
        just = left
        fontsize = 8pt
        height = 15pt
    ;

    class SystemFooter/
        just = left
        font = fonts("font")
        fontweight = bold
        fontsize = 8pt
        height = 15pt
        foreground = red
    ;

    class SystemFooter2/
        fontweight = light
        foreground = colors('titlecolor')
    ;


   end;                                                                       
run;

