cd ..\data\server\
svn up
svn st > ..\st.log
echo --------------------------------------------------------- >> ..\st.log
svn diff >> ..\st.log
notepad ..\st.log