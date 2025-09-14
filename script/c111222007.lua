-- Lesser Lord Kusanali
local s,id=GetID()
function s.initial_effect(c)
	-- Fusion material
	c:EnableReviveLimit()
	Fusion.AddProcMix(c,true,true,
		function(c) return c:IsSetCard(0x1800) and c:IsType(TYPE_MONSTER) end, -- Sumeru monster, example setcode 0x1800
		function(c) return c:IsSetCard(0x700) and c:IsAttribute(ATTRIBUTE_LIGHT) end) -- Genshin LIGHT

	-- Opponent cannot respond to your Genshin cards
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(0,1)
	e1:SetValue(s.aclimit)
	c:RegisterEffect(e1)

	-- Quick effect: redistribute Akara Counters
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	e2:SetCondition(s.qcond)
	e2:SetCost(s.qcost)
	e2:SetTarget(s.qtg)
	e2:SetOperation(s.qop)
	c:RegisterEffect(e2)

	-- Gain Akara Counter when another card places counters
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD)
	e3:SetCode(EVENT_CUSTOM+id+1) -- custom counter event
	e3:SetRange(LOCATION_MZONE)
	e3:SetOperation(s.addcounter)
	c:RegisterEffect(e3)

	-- Quick effect: prevent destruction or damage
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_PRE_BATTLE_DAMAGE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCondition(s.damcon)
	e4:SetCost(s.damcost)
	e4:SetOperation(s.damop)
	c:RegisterEffect(e4)
end

-- Opponent cannot respond to your Genshin cards
function s.aclimit(e,re,tp)
	return re:GetHandler():IsSetCard(0x700)
end

-- Quick effect placeholders
function s.qcond(e,tp,eg,ep,ev,re,r,rp)
	return true
end
function s.qcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:GetCounter(0x1)>0 end -- example Akara Counter ID=0x1
	-- remove counters as cost
	local ct=c:GetCounter(0x1)
	c:RemoveCounter(tp,0x1,ct,REASON_COST)
	e:SetLabel(ct)
end
function s.qtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
end
function s.qop(e,tp,eg,ep,ev,re,r,rp)
	local ct=e:GetLabel()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectMatchingCard(tp,Card.IsFaceup,tp,LOCATION_MZONE,0,1,1,nil)
	if g:GetCount()>0 then
		local tc=g:GetFirst()
		tc:AddCounter(0x1,ct)
	end
end

function s.addcounter(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	c:AddCounter(0x1,1)
end

function s.damcon(e,tp,eg,ep,ev,re,r,rp)
	return true -- you can add battle/effect destruction check
end
function s.damcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:GetCounter(0x1)>0 end
	c:RemoveCounter(tp,0x1,1,REASON_COST)
end
function s.damop(e,tp,eg,ep,ev,re,r,rp)
	Duel.ChangeBattleDamage(tp,0)
end
