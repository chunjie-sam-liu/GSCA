import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { ImmuneRoutingModule } from './immune-routing.module';
import { ImmuneComponent } from './immune.component';
import { SharedModule } from 'src/app/shared/shared.module';
import { SearchBoxComponent } from './search-box/search-box.component';
import { ImmuneExprComponent } from './immune-expr/immune-expr.component';
import { ImmuneCnvComponent } from './immune-cnv/immune-cnv.component';

@NgModule({
  declarations: [ImmuneComponent, SearchBoxComponent, ImmuneExprComponent, ImmuneCnvComponent],
  imports: [CommonModule, ImmuneRoutingModule, SharedModule],
})
export class ImmuneModule {}
