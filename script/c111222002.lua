--Navia
local s,id=GetID()
function s.initial_effect(c)
	--Cannot be destroyed by card effects
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e1:SetValue(1)
	c:RegisterEffect(e1)

	-- Add 1 "Genshin" Spell/Trap from Deck to Hand when Summoned
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCountLimit(1,id)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
    -- Trigger also on Special Summon
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)

	--Destroy 1 card on the field when another "Genshin" monster effect is activated
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,1))
    e4:SetCategory(CATEGORY_DESTROY)
    e4:SetType(EFFECT_TYPE_QUICK_O)
    e4:SetCode(EVENT_CHAINING)
    e4:SetProperty(EFFECT_FLAG_CARD_TARGET + EFFECT_FLAG_DELAY)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(1, id+1)  -- once per turn
    e4:SetCondition(s.descon)
    e4:SetTarget(s.destg)
    e4:SetOperation(s.desop)
    c:RegisterEffect(e4)


	--Fusion Summon 1 "Genshin" monster
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,2))
	e5:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e5:SetType(EFFECT_TYPE_IGNITION)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCountLimit(1,id+2)
	e5:SetCondition(s.fuscon)
	e5:SetTarget(s.fustg)
	e5:SetOperation(s.fusop)
	c:RegisterEffect(e5)
end
s.listed_series={0x700}

--Filter for "Genshin" Spell/Trap cards
function s.thfilter(c)
	return c:IsSetCard(0x700) and c:IsSpellTrap() and c:IsAbleToHand()
end
--Activation requirement for adding card to hand
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
--Operation for adding card to hand
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- Trigger only if another "Genshin" monster (not this card) activates its effect
function s.descon(e,tp,eg,ep,ev,re,r,rp)
    Debug.Message("condition passed")
    local rc = re:GetHandler()
    return rc and rc:IsSetCard(0x700)      -- Must be a "Genshin" monster
       and rc:IsType(TYPE_MONSTER)         -- Must be a monster
       and rc ~= e:GetHandler()            -- Must not be this card
end

--Activation requirement for destroying a card
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsOnField() end
    if chk==0 then return Duel.IsExistingTarget(aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local g = Duel.SelectTarget(tp, aux.TRUE, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, 1, nil)
    Duel.SetOperationInfo(0, CATEGORY_DESTROY, g, 1, 0, 0)
end

--Operation for destroying a card
function s.desop(e,tp,eg,ep,ev,re,r,rp)
    local tc = Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        Duel.Destroy(tc, REASON_EFFECT)
    end
end


--Condition for Fusion Summon: if you control 2 or more "Genshin" monsters
function s.fuscon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetMatchingGroupCount(Card.IsSetCard,tp,LOCATION_MZONE,0,nil,0x700)>=2
end
--Filter for "Genshin" Fusion Monsters
function s.fusfilter(c,e,tp,m,f,chkf)
	return c:IsType(TYPE_FUSION) and c:IsSetCard(0x700) and (not f or f(c))
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false) and c:CheckFusionMaterial(m,nil,chkf)
end
--Activation requirement for Fusion Summon
function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		local chkf=tp
		local mg=Duel.GetFusionMaterial(tp)
		local res=Duel.IsExistingMatchingCard(s.fusfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg,nil,chkf)
		if not res then
			local ce=Duel.GetChainMaterial(tp)
			if ce~=nil then
				local fgroup=ce:GetTarget()
				local mg3=fgroup(ce,e,tp)
				local mf=ce:GetValue()
				res=Duel.IsExistingMatchingCard(s.fusfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg3,mf,chkf)
			end
		end
		return res
	end
	Duel.SetOperationInfo(0,CATEGORY_FUSION_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_MZONE)
end
--Operation for Fusion Summon
function s.fusop(e,tp,eg,ep,ev,re,r,rp)
	local chkf=tp
	local mg=Duel.GetFusionMaterial(tp):Filter(Card.IsOnField,nil)
	local sg1=Duel.GetMatchingGroup(Card.IsCanBeFusionMaterial,tp,LOCATION_HAND,0,nil)
	mg:Merge(sg1)
	
	local res=false
	local ce=Duel.GetChainMaterial(tp)
	if ce~=nil then
		local fgroup=ce:GetTarget()
		local mg3=fgroup(ce,e,tp)
		local mf=ce:GetValue()
		if Duel.IsExistingMatchingCard(s.fusfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg3,mf,chkf) then
			res=true
		end
	end
	if not res and Duel.IsExistingMatchingCard(s.fusfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg,nil,chkf) then
		res=true
	end
	
	if res then
		local fcard=nil
		if ce~=nil then
			local fgroup=ce:GetTarget()
			local mg3=fgroup(ce,e,tp)
			local mf=ce:GetValue()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			fcard=Duel.SelectMatchingCard(tp,s.fusfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,mg3,mf,chkf):GetFirst()
		else
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			fcard=Duel.SelectMatchingCard(tp,s.fusfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,mg,nil,chkf):GetFirst()
		end
		
		if fcard then
			if ce~=nil then
				local fgroup=ce:GetTarget()
				local mg3=fgroup(ce,e,tp)
				local mf=ce:GetValue()
				local mat=Duel.SelectFusionMaterial(tp,fcard,mg3,nil,chkf)
				fcard:SetMaterial(mat)
				Duel.SendtoGrave(mat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
				Duel.BreakEffect()
				Duel.SpecialSummon(fcard,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
			else
				local mat=Duel.SelectFusionMaterial(tp,fcard,mg,nil,chkf)
				fcard:SetMaterial(mat)
				Duel.SendtoGrave(mat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
				Duel.BreakEffect()
				Duel.SpecialSummon(fcard,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
			end
			fcard:CompleteProcedure()
		end
	end
end
