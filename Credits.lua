local _, T = ...

function T.CreditsData(vh, li)
	local L = T.L
	vh(L"OPie")
	li((L"%s — author of the original addon."):format("|cffffd200foxlit|r"))
	vh(L"Adaptation")
	li((L"%s — adaptation for World of Warcraft 3.3.5a."):format("|cffffd200Poslevkusie|r"))
	vh(L"Sirus")
	li((L"%s — optimization for Sirus."):format("|cffffd200Accidev|r"))
end
