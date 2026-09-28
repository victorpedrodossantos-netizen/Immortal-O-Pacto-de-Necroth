class_name GameEnums
extends RefCounted

## Enumerações centrais para o projeto Immortal: O Pacto de Necroth

enum DimensionMode {
	MODE_2D,
	MODE_25D,
	MODE_3D
}

enum DimensionStatus {
	ACTIVE,
	UNDER_MAINTENANCE
}

enum Faction {
	PACTO_NECROTH,      ## Exército e invocações de Necroth
	CHAMA_PETREA,       ## Inquisição e guerreiros sagrados
	FENDIDOS_DE_FERRO,  ## Clãs marciais e guerreiros subterrâneos
	PUTRIDOS_DO_LIMO,   ## Enxames rastejantes necróticos
	VAGANTES_DO_VEU     ## Horrores cósmicos e entidades ancestrais
}

enum AlertLevel {
	CALMO,              ## Patrulha sem suspeita
	SUSPEITO,           ## Som ou vulto percebido
	INVESTIGANDO,       ## Deslocamento até a fonte do ruído
	COMBATE_ATIVO,      ## Alvo confirmado e engajamento tático
	BUSCA_CAUTELOSA     ## Alvo perdido de vista; cobertura mútua
}

enum TacticalRole {
	COMANDANTE,         ## Carrasco do Limbo / Líderes de esquadrão
	TROPA_CHOQUE,       ## Unidades de frente e absorção de impacto
	FLANQUEADOR,        ## Unidades ágeis para ataques pelas costas
	SUPORTE_DISTANCIA,  ## Arqueiros / Taumaturgos
	ENXAME              ## Lacaios menores de pressão contínua
}
