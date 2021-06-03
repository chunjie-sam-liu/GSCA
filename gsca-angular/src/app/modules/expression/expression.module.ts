import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { ExpressionRoutingModule } from './expression-routing.module';
import { ExpressionComponent } from './expression.component';
import { SearchBoxComponent } from './search-box/search-box.component';
import { SharedModule } from 'src/app/shared/shared.module';
import { DegComponent } from './deg/deg.component';
import { SurvivalComponent } from './survival/survival.component';
import { SubtypeComponent } from './subtype/subtype.component';
import { StageComponent } from './stage/stage.component';
import { GeneSetComponent } from './gene-set/gene-set.component';
import { GseaComponent } from './gsea/gsea.component';
import { GsvaSurvivalComponent } from './gsva-survival/gsva-survival.component';
import { GsvaStageComponent } from './gsva-stage/gsva-stage.component';
import { GsvaSubtypeComponent } from './gsva-subtype/gsva-subtype.component';
import { PparComponent } from './ppar/ppar.component';
import { GsvaRppaComponent } from './gsva-rppa/gsva-rppa.component';
import { DocComponent } from './deg/doc/doc.component';
import { DocGeneSetComponent } from './gene-set/doc-gene-set/doc-gene-set.component';
import { DocSeaComponent } from './gsea/doc-sea/doc-sea.component';
import { DocGsvaStageComponent } from './gsva-stage/doc-gsva-stage/doc-gsva-stage.component';
import { DocGsvaSubtypeComponent } from './gsva-subtype/doc-gsva-subtype/doc-gsva-subtype.component';
import { DocGsvaSurvivalComponent } from './gsva-survival/doc-gsva-survival/doc-gsva-survival.component';
import { DocPparComponent } from './ppar/doc-ppar/doc-ppar.component';
import { DocStageComponent } from './stage/doc-stage/doc-stage.component';
import { DocSubtypeComponent } from './subtype/doc-subtype/doc-subtype.component';
import { DocSurvivalComponent } from './survival/doc-survival/doc-survival.component';
import { DocGsvaRppaComponent } from './gsva-rppa/doc-gsva-rppa/doc-gsva-rppa.component';
import { PathwayEnrichmentComponent } from './pathway-enrichment/pathway-enrichment.component';
import { GsvascoreComponent } from './gsvascore/gsvascore.component';
import { DocGsvascoreComponent } from './gsvascore/doc-gsvascore/doc-gsvascore.component';

@NgModule({
  declarations: [
    ExpressionComponent,
    SearchBoxComponent,
    DegComponent,
    SurvivalComponent,
    SubtypeComponent,
    StageComponent,
    GeneSetComponent,
    GseaComponent,
    GsvaSurvivalComponent,
    GsvaStageComponent,
    GsvaSubtypeComponent,
    PparComponent,
    GsvaRppaComponent,
    DocComponent,
    DocGeneSetComponent,
    DocSeaComponent,
    DocGsvaStageComponent,
    DocGsvaSubtypeComponent,
    DocGsvaSurvivalComponent,
    DocPparComponent,
    DocStageComponent,
    DocSubtypeComponent,
    DocSurvivalComponent,
    DocGsvaRppaComponent,
    PathwayEnrichmentComponent,
    GsvascoreComponent,
    DocGsvascoreComponent,
  ],
  imports: [CommonModule, ExpressionRoutingModule, SharedModule],
})
export class ExpressionModule {}
