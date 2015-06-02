/*
    Program Name: XLnum2alpha.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date; 2014/04/13
*/

%macro XLnum2alpha(num=, alpha=);

    length _numIn_ 8 _alphaout_ $32;
    call missing(_alphaout_,_numIn_);

    _numIn_ = &num;
    _int = int(_numIn_ / 26) - (int(_numIn_/26) = _numIn_/26);
    _mod = _numIn_ - 26 * _int;
    _alphaout_ = byte(97 + _mod - 1);

    do while (_int > 0);
        _numIn_ = _int;
        _int = int(_numIn_ / 26) - (int(_numIn_/26) = _numIn_/26);
        _mod = _numIn_ - 26 * _int;
        _alphaout_ = byte(97 + _mod - 1)||strip(_alphaout_);
    end;

    &alpha = upcase(_alphaout_);

%mend XLnum2alpha;

 
