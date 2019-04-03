function formatPlot(tstr, xstr, ystr, fontName, axFSz)
%% make it look nice
method = 1;
switch method
    case 1
        title(tstr,'Interpreter','LaTeX','FontSize',18)
        xlabel(xstr,'Interpreter','LaTeX','FontSize',axFSz)
        ylabel(ystr,'Interpreter','LaTeX','FontSize',axFSz)
        
    case 2
        title(tstr,'FontSize',18)
        set(gca,'FontName',fontName,'FontSize',18)
        xlabel(xstr,'FontName',fontName,'FontSize',axFSz)
        ylabel(ystr,'FontName',fontName,'FontSize',axFSz)
end