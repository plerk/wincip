FROM mcr.microsoft.com/windows/servercore:ltsc2019

COPY bin c:/bin
ENV PERL_CPANM_HOME c:\\tmp\\cpanm
RUN setx path "%PATH%;c:\bin"

##
## INSTALL MSYS
##
RUN mkdir \opt\msys
RUN cd \opt\msys && \
    curl -s -O -L https://sourceforge.net/projects/mingw/files/Installer/mingw-get/mingw-get-0.6.2-beta-20131004-1/mingw-get-0.6.2-mingw32-beta-20131004-1-bin.zip && \
    tar xf mingw-get-0.6.2-mingw32-beta-20131004-1-bin.zip && \
    c:\opt\msys\bin\mingw-get install msys && \
    c:\opt\msys\bin\mingw-get install msys-m4 && \
    c:\opt\msys\bin\mingw-get install msys-perl && \
    rmdir /s/q var\cache\mingw-get\packages && \
    rmdir /s/q msys\1.0\share\doc && \
    rmdir /s/q msys\1.0\share\man && \
    del mingw-get-0.6.2-mingw32-beta-20131004-1-bin.zip
ENV PERL_ALIEN_MSYS_BIN c:\\opt\\msys\\msys\\1.0\\bin


##
## INSTALL cmake
## 
RUN cd \opt && \
    curl -s -O -L https://github.com/Kitware/CMake/releases/download/v3.16.1/cmake-3.16.1-win64-x64.zip && \
    tar xf cmake-3.16.1-win64-x64.zip  && \
    move cmake-3.16.1-win64-x64 cmake && \
    setx path "%PATH%;c:\opt\cmake\bin"


##
## INSTALL rust
##
ENV CARGO_HOME=c:\\opt\\rust\\cargo
ENV RUSTUP_HOME=c:\\opt\\rust\\rustup
RUN setx path "%PATH%;c:\opt\rust\cargo\bin" && \
    mkdir \tmp && \
    cd \tmp && \
    curl -s -o rustup-init.exe https://win.rustup.rs/x86_64 && \
    rustup-init -q -y --no-modify-path --default-host x86_64-pc-windows-gnu && \
    del rustup-init.exe


##
## INSTALL Go
##
RUN setx gopath "%USERPROFILE%\go" && \
    setx path "%PATH%;%USERPROFILE%\go\bin;c:\opt\go\bin" && \
    cd \opt && \
    curl -s -O https://dl.google.com/go/go1.13.2.windows-amd64.zip && \
    tar xf go1.13.2.windows-amd64.zip && \
    del go1.13.2.windows-amd64.zip

##
## INSTALL Dist::Zilla
##

RUN mkdir \dzil \cache \work
RUN cd \dzil                                                                                  && \
    curl -s -O http://strawberryperl.com/download/5.30.1.1/strawberry-perl-5.30.1.1-64bit.zip && \
    tar xf strawberry-perl-5.30.1.1-64bit.zip                                                 && \
    del strawberry-perl-5.30.1.1-64bit.zip                                                    && \
    c:\dzil\perl\bin\perl relocation.pl.bat --quiet                                           && \
    echo done

RUN dzil-wrapper cpanm -n App::pwhich
RUN dzil-wrapper cpanm -n Dist::Zilla
RUN dzil-wrapper cpanm -n Dist::Zilla::PluginBundle::Author::Plicease


##
## INSTALL Strawberry Perl
##

RUN mkdir \perl                                                                               && \
    cd \perl                                                                                  && \
    curl -s -O http://strawberryperl.com/download/5.30.1.1/strawberry-perl-5.30.1.1-64bit.zip && \
    tar xf strawberry-perl-5.30.1.1-64bit.zip                                                 && \
    del strawberry-perl-5.30.1.1-64bit.zip                                                    && \
    c:\perl\perl\bin\perl relocation.pl.bat --quiet                                           && \
    echo done

RUN setx path "c:\cache\perl\bin;c:\perl\perl\site\bin;c:\perl\perl\bin;c:\perl\c\bin;%PATH%"
ENV PERL5LIB c:/cache/perl/lib/perl5
ENV PERL_LOCAL_LIB_ROOT c:/cache/perl/lib/perl5
ENV PERL_MB_OPT --install_base c:/cache/perl
ENV PERL_MM_OPT INSTALL_BASE=c:/cache/perl

WORKDIR c:/work