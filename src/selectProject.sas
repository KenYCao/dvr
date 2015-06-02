/*
    Program Name: selectProject.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2013/10/29
        
*/

%macro selectProject(); /*returns project name (folder name) as macro variable: whichProject*/

    %local wrongcnt; /*# of times user types incorrect result*/
    %local rootdir2; /*Root directory of DVP package: directory of programs dvp.sas*/


    %let wrongcnt = 0; /*Initialization*/



    /*
        setup a temporary library of which directory is location of dvp.sas
        get directory of the temporary library
    */

    libname dummy '.'; 
    %let rootdir2 = %sysfunc(pathname(dummy));
    libname dummy clear;


    **********************************************************************;
    *SAS Window Enviornment to let user choose project*;
    **********************************************************************;

    %CHOOSEPROJECT:

    data _null_;

        length whichProject $32;
        whichProject = "&whichProject";

        window whichProject 
            color = white   icolumn = 5 irow = 5 columns = 120 rows = 25
            #3 @35 " Welcome to Use Q2 DVP Report Application " attr = rev_video color = green
            #5 @5  "Please INPUT name of project here: " color = blue whichProject required = yes 
            #7 @5  "Press Enter or issue ""End"" command in command line at top left corner to exit this window" color = green
        ;

        display whichProject;

        call symput('whichProject', strip(whichProject));
        stop;

    run; 


    %ValidateInput:

    *deal with user input;
    %let whichProject = %sysfunc(strip(&whichProject));
    *validate user input;
    %if %sysfunc(fileexist(project/&whichProject)) = 0 %then
        %do;

            %let wrongcnt = %eval(&wrongcnt+1);

            data _null_;

                window wrongProject 
                color = white icolumn = 5 irow = 5  columns = 180 rows = 25
                    #3  @35 " Something's not right...  " attr = rev_video color = red
                    #5  @5  "Folder ""&whichProject"" was not found under folder"
                    #7  @7  "&rootdir2\project"
                    #9  @5  "Press Enter to go back to Welcome Window to re-input the name of setup program." color = green
                    ;

                display wrongProject;
                stop;

            run;

            %if &wrongcnt<5 %then %goto CHOOSEPROJECT;
            %else
                %do;
                    data _null_;

                        window forceexit 
                        color = white icolumn = 5 irow = 5  columns = 180 rows = 25
                            #3  @35 " Sorry...  " attr = rev_video color = red
                            #5  @5  "The project you input is still not found." 
                            #7  @5  "Please go to [&rootdir2\project] check if any spelling err&blank.or." 
                            #9  @5  "Then, please make sure current work directory for this SAS session:"
                            #11 @7  " &rootdir2 " color = blue
                            #13 @5  "is the root directory of DVP Application" 
                            #13 @5  "Press Enter to stop running and start again" 
                            #15 @5  "If this window keeps arising, please contact your local expert." color = green
                            #17 @5  "Goodbye!" color = green
                            ;
                    display forceexit;
                    stop;
                run;
                %end;
            %return;
        %end;
    %else 
        %do;
            data _null_;
                window success
                    color = white
                    icolumn = 5 irow = 5
                    columns = 150 rows = 25
                    #3 @35 "Congratulations!" attr = rev_video color = red
                    #5 @5  "Your DVP report is on the way." color = green
                    #7 @5  "Please Press Enter to Exit This Window and Start Execution." color = green
                    #9 @5  "Enjony!" color = green
                ;
                display success;
                stop;
            run;
        %end;


%mend selectProject;
