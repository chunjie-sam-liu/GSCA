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
  ],
  imports: [CommonModule, ExpressionRoutingModule, SharedModule],
})
export class ExpressionModule {}
