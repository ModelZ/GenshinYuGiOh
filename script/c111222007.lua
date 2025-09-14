-- Lesser Lord Kusanali
local s,id=GetID()
function s.initial_effect(c)
	-- Fusion material
	c:EnableReviveLimit()
    c:EnableCounterPermit(0x301) -- Can Place Akara Counter 
	Fusion.AddProcMix(c,true,true,s.sumerufilter,s.lightfilter)

	-- Opponent cannot respond to your Genshin cards
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(0,1)
	e1:SetValue(s.aclimit)
	c:RegisterEffect(e1)

	-- Add Akara Counters
	local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,2))
    e2:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD)
    e2:SetCode(EVENT_ADD_COUNTER) -- triggers whenever counters are placed
    e2:SetRange(LOCATION_MZONE)
    e2:SetOperation(s.acop)
    c:RegisterEffect(e2)

    -- You can remove any number of Akara counter(s) and target your monster that had the counter on it on the field (Quick Effect); 
    -- increase the number of that Counter by the number of removed Akara counter(s).

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

function s.IsExactSet(c,setcode)
    local codes={c:GetSetCard()}
    for _,v in ipairs(codes) do
        if v==setcode then return true end
    end
    return false
end

--Fusion materials
function s.sumerufilter(c,fc,sumtype,tp)
    return s.IsExactSet(c,0x4700) and c:IsType(TYPE_MONSTER)  -- Sumeru monster
end

function s.lightfilter(c,fc,sumtype,tp)
	return c:IsSetCard(0x700) and c:IsAttribute(ATTRIBUTE_LIGHT)  -- "Genshin" LIGHT monster
end

-- Opponent cannot respond to your Genshin cards
function s.aclimit(e,re,tp)
	return re:GetHandler():IsSetCard(0x700)
end

-- Place a Akara Counter when other's card place a counter (ignores itself)
function s.acop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    -- eg = group of cards that got counters
    for tc in aux.Next(eg) do
        if tc~=c then
            -- Another card got counters → give this card 1 Akara Counter
            c:AddCounter(0x301,1)
            break -- only once per event, no matter how many got counters
        end
    end
end

function s.damcon(e,tp,eg,ep,ev,re,r,rp)
	return true -- you can add battle/effect destruction check
end
function s.damcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:GetCounter(0x301)>0 end
	c:RemoveCounter(tp,0x301,1,REASON_COST)
end
function s.damop(e,tp,eg,ep,ev,re,r,rp)
	Duel.ChangeBattleDamage(tp,0)
end
