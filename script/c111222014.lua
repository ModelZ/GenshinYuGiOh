--My Brother's
local s,id=GetID()
function s.initial_effect(c)
    --Special Summon materials when "Genshin" Fusion monster leaves field
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_TO_GRAVE) -- Trigger when a monster is sent from field to GY
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetRange(LOCATION_SZONE) -- Spell/Trap zone
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)
end

--Condition: if a "Genshin" Fusion monster controlled by you left the field by opponent effect
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(function(c,tp)
        return c:IsPreviousLocation(LOCATION_MZONE)
            and c:IsPreviousControler(tp)
            and c:IsType(TYPE_FUSION)
            and c:IsSetCard(0x700)
            and c:IsReason(REASON_EFFECT)
            and rp~=tp -- caused by opponent
    end, 1, nil, tp)
end

--Targeting all Fusion Materials of that Fusion Monster
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        local g=Group.CreateGroup()
        for tc in aux.Next(eg) do
            if tc:IsPreviousLocation(LOCATION_MZONE) and tc:IsType(TYPE_FUSION) and tc:IsSetCard(0x700) then
                local mat=tc:GetMaterial()
                g:Merge(mat)
            end
        end
        g=g:Filter(function(c,e,tp)
            return c:IsCanBeSpecialSummoned(e,0,tp,false,false)
        end,nil,e,tp)
        return #g>0
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE+LOCATION_HAND+LOCATION_DECK+LOCATION_REMOVED)
end

--Operation: Special Summon all materials as possible
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local g=Group.CreateGroup()
    for tc in aux.Next(eg) do
        if tc:IsPreviousLocation(LOCATION_MZONE) and tc:IsType(TYPE_FUSION) and tc:IsSetCard(0x700) then
            local mat=tc:GetMaterial()
            g:Merge(mat)
        end
    end
    g=g:Filter(function(c,e,tp)
        return c:IsCanBeSpecialSummoned(e,0,tp,false,false)
    end,nil,e,tp)
    if #g==0 then return end

    local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
    if ft<=0 then return end

    if #g>ft then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        g=g:Select(tp,ft,ft,nil)
    end
    Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
end
