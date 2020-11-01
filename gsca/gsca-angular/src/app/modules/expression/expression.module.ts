import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { ExpressionRoutingModule } from './expression-routing.module';
import { ExpressionComponent } from './expression.component';
import { SearchBoxComponent } from './search-box/search-box.component';
import { SharedModule } from 'src/app/shared/shared.module';
import { DegComponent } from './deg/deg.component';
import { ColorDiyComponent } from './color-diy/color-diy.component';

@NgModule({
  declarations: [ExpressionComponent, SearchBoxComponent, DegComponent, ColorDiyComponent],
  imports: [CommonModule, ExpressionRoutingModule, SharedModule],
})
export class ExpressionModule {}
