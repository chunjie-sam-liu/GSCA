import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { DocImmMethyComponent } from './doc-imm-methy.component';

describe('DocImmMethyComponent', () => {
  let component: DocImmMethyComponent;
  let fixture: ComponentFixture<DocImmMethyComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ DocImmMethyComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DocImmMethyComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
