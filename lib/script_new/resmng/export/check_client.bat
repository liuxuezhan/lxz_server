cd ..\data\client\
svn up
svn st > ..\st.log
echo --------------------------------------------------------- >> ..\st.log
svn diff >> ..\st.log
notepad ..\st.log