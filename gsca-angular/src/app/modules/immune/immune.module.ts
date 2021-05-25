import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { ImmuneRoutingModule } from './immune-routing.module';
import { ImmuneComponent } from './immune.component';
import { SharedModule } from 'src/app/shared/shared.module';
import { SearchBoxComponent } from './search-box/search-box.component';
import { ImmuneExprComponent } from './immune-expr/immune-expr.component';
import { ImmuneCnvComponent } from './immune-cnv/immune-cnv.component';
import { ImmuneSnvComponent } from './immune-snv/immune-snv.component';
import { ImmuneMethyComponent } from './immune-methy/immune-methy.component';
import { ImmuneCnvGsvaComponent } from './immune-cnv-gsva/immune-cnv-gsva.component';
import { DocImmCnvComponent } from './immune-cnv/doc-imm-cnv/doc-imm-cnv.component';
import { DocImmExprComponent } from './immune-expr/doc-imm-expr/doc-imm-expr.component';
import { DocImmMethyComponent } from './immune-methy/doc-imm-methy/doc-imm-methy.component';
import { DocImmSnvComponent } from './immune-snv/doc-imm-snv/doc-imm-snv.component';
import { ImmuneGsvaComponent } from './immune-gsva/immune-gsva.component';
import { ImmuneSnvGenesetComponent } from './immune-snv-geneset/immune-snv-geneset.component';
import { DocImmuneCnvGsvaComponent } from './immune-cnv-gsva/doc-immune-cnv-gsva/doc-immune-cnv-gsva.component';
import { DocImmuneGsvaComponent } from './immune-gsva/doc-immune-gsva/doc-immune-gsva.component';
import { DocImmuneSnvGenesetComponent } from './immune-snv-geneset/doc-immune-snv-geneset/doc-immune-snv-geneset.component';

@NgModule({
  declarations: [ImmuneComponent, SearchBoxComponent, ImmuneExprComponent, ImmuneCnvComponent, ImmuneSnvComponent, ImmuneMethyComponent, ImmuneCnvGsvaComponent, DocImmCnvComponent, DocImmExprComponent, DocImmMethyComponent, DocImmSnvComponent, ImmuneGsvaComponent, ImmuneSnvGenesetComponent, DocImmuneCnvGsvaComponent, DocImmuneGsvaComponent, DocImmuneSnvGenesetComponent],
  imports: [CommonModule, ImmuneRoutingModule, SharedModule],
})
export class ImmuneModule {}
