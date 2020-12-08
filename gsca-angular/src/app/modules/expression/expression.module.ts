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

@NgModule({
  declarations: [ExpressionComponent, SearchBoxComponent, DegComponent, SurvivalComponent, SubtypeComponent, StageComponent],
  imports: [CommonModule, ExpressionRoutingModule, SharedModule],
})
export class ExpressionModule {}
