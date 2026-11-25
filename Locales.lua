--------------------------------------------------------------------------------
-- Translations. The addon follows the game client's language:
-- ns.L["English text"] is translated below, English otherwise. Spell names and
-- ranks ("Rank 3") always come from the game, already translated.
-- To add a language, copy the ptBR block and change the locale code.
--------------------------------------------------------------------------------

local _, ns = ...

local L = setmetatable({}, { __index = function(_, key) return key end })
ns.L = L

local locale = GetLocale and GetLocale() or "enUS"

if locale == "ptBR" then
	-- spellbook button (tooltip)
	L["To update:"] = "Para atualizar:"
	L["(%d buttons)"] = "(%d botões)"
	L["Every spell on your bars is at its highest rank."] = "Todas as magias das suas barras estão no grau mais alto."
	L["Not on your bars:"] = "Fora das suas barras:"
	L["and %d more"] = "e mais %d"
	L["Click: update your bars"] = "Clique: atualiza as suas barras"
	L["Right-click: choose spells to ignore (/refine ignored)"] = "Botão direito: escolher magias a ignorar (/refine ignored)"

	-- ignored spells window
	L["Spells not on your bars. Tick the ones to ignore."] = "Magias fora das suas barras. Marque as que quer ignorar."
	L["All your class spells are on your bars."] = "Todas as suas magias de classe estão nas barras."

	-- updating
	L["You can't change your action bars in combat."] = "Não é possível alterar as barras de ação em combate."
	L["Drop what's on your cursor first."] = "Solte primeiro o que está no cursor."
	L["Some action bar buttons couldn't be changed. Type /refine diag."] =
		"Alguns botões das barras de ação não puderam ser alterados. Digite /refine diag."

	-- trainer
	L["open the spellbook (%s)"] = "abra o grimório (%s)"
	L["open the spellbook"] = "abra o grimório"
	L["1 spell on your bars has a new rank: %s to update it."] =
		"1 magia das suas barras tem um grau novo: %s para atualizá-la."
	L["%d spells on your bars have a new rank: %s to update them."] =
		"%d magias das suas barras têm um grau novo: %s para atualizá-las."

	-- slash commands
	L["Commands:"] = "Comandos:"
	L["All commands:"] = "Todos os comandos:"
	L["all commands"] = "todos os comandos"
	L["update your action bars (the same as the spellbook button)"] =
		"atualiza as barras de ação (o mesmo que o botão do grimório)"
	L["don't list a spell that isn't on your bars"] = "deixa de listar uma magia que não está nas barras"
	L["list an ignored spell again"] = "volta a listar uma magia ignorada"
	L["open the window to choose the spells to ignore"] = "abre a janela para escolher as magias a ignorar"
	L["turn the chat line after the trainer on or off"] = "liga/desliga o aviso no chat depois do treinador"
	L["check what this client allows"] = "verifica o que este cliente permite"
	L["toggle debug messages"] = "liga/desliga mensagens de depuração"
	L["Updated %d action bar button(s)."] = "%d botão(ões) das barras de ação atualizado(s)."
	L["No spell called \"%s\" in your spellbook."] = "Nenhuma magia chamada \"%s\" no seu grimório."
	L["Ignored: %s."] = "Ignorada: %s."
	L["Listed again: %s."] = "Listada de novo: %s."
	L["\"%s\" isn't ignored."] = "\"%s\" não está ignorada."
	L["Chat line after the trainer: on."] = "Aviso no chat depois do treinador: ligado."
	L["Chat line after the trainer: off."] = "Aviso no chat depois do treinador: desligado."
	L["Debug messages on."] = "Mensagens de depuração ligadas."
	L["Debug messages off."] = "Mensagens de depuração desligadas."
end
